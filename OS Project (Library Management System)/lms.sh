#!/bin/bash

# Arrays for books, students, and admin information
declare -a books=("Islamic Studies" "Computer Science" "Pak Studies")
declare -A bookCopies=( ["Islamic Studies"]=3 ["Computer Science"]=5 ["Pak Studies"]=2 )
declare -a studentsNames=("Munaza" "Ali" "Ahmed" "Sara")
declare -a studentsRegNo=("BCS-037" "BCS-038" "BCS-039" "BCS-040")
declare -a studentsDep=("BSCS" "BSCS" "BSCS" "BSCS")
declare -A studentsBooks=() # Tracks books issued to each student
declare -A adminCredentials=( ["admin001"]="pass123" ["admin002"]="pass456" ["admin003"]="pass789" ["admin004"]="pass101" )

# Declare an associative array to track books and return dates for each student registration number
declare -A studentsBooks
declare -A studentsReturnDates
# Set a daily penalty rate (e.g., 100 rupees per day)
dailyPenalty=100

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Admin Login Function
admin_login() {
    echo -e "${CYAN}Enter admin login credentials:${NC}"
    read -p "Enter your admin ID: " adminID
    read -sp "Enter your password: " password
    echo

    # Check if the entered admin ID exists in the adminCredentials and if the password matches
    if [[ -v adminCredentials[$adminID] && ${adminCredentials[$adminID]} == "$password" ]]; then
        echo -e "${GREEN}Login successful! Welcome, $adminID.${NC}"
        main_menu
    else
        echo -e "${RED}Invalid credentials. Access denied!${NC}"
        exit 1
    fi
}

# Main Menu accessible only after admin login
main_menu() {
    echo -e "${YELLOW}----------------WELCOME TO LIBRARY MANAGEMENT SYSTEM----------------${NC}"
    echo "----------------Main Menu----------------"
    echo "1. Manage Books"
    echo "2. Manage Students"
    echo "3. Issue Book"
    echo "4. Exit"
    read -p "Please enter your choice: " userChoice
    case $userChoice in
        1) manage_books ;;
        2) manage_students ;;
        3) issue_book ;;
        4) exit 0 ;;
        *) echo -e "${RED}Invalid choice!${NC}" ; main_menu ;;
    esac
}

# Manage Books
manage_books() {
    echo -e "${YELLOW}----------------Manage Books----------------${NC}"
    echo "1. Add Book"
    echo "2. Edit Book"
    echo "3. Delete Book"
    echo "4. Search Book"
    echo "5. View Books"
    echo "6. Return Book"
    echo "7. Return to Main Menu"
    read -p "Please enter your choice: " choice
    case $choice in
        1) add_book ;;
        2) edit_book ;;
        3) delete_book ;;
        4) search_book ;;
        5) view_books ;;
	6) return_book ;;
        7) main_menu ;;
        *) echo -e "${RED}Invalid choice!${NC}" ; manage_books ;;
    esac
}

add_book() {
    read -p "Enter book name to be added: " bookName
    read -p "Enter number of copies to add: " copies
    if [[ -v bookCopies["$bookName"] ]]; then
        bookCopies["$bookName"]=$((bookCopies["$bookName"] + copies))
        echo -e "${GREEN}Updated book copies!${NC} ${YELLOW}$bookName now has ${bookCopies[$bookName]} copies.${NC}"
    else
        books+=("$bookName")
        bookCopies["$bookName"]=$copies
        echo -e "${GREEN}Book added successfully!${NC}"
    fi
    view_books
}

edit_book() {
    read -p "Enter the name of the book you want to edit: " bookName
    if [[ -v bookCopies["$bookName"] ]]; then
        read -p "Enter the new name for the book (or press Enter to keep '$bookName'): " newBookName
        read -p "Enter the new number of copies: " newCopies
        newBookName=${newBookName:-$bookName}
        bookCopies["$newBookName"]=$newCopies
        if [[ "$newBookName" != "$bookName" ]]; then
            for i in "${!books[@]}"; do
                if [[ "${books[$i]}" == "$bookName" ]]; then
                    books[$i]=$newBookName
                    break
                fi
            done
            unset 'bookCopies[$bookName]'
        fi
        echo -e "${GREEN}Book updated successfully!${NC}"
        view_books
    else
        echo -e "${RED}Book not found!${NC}"
        manage_books
    fi
}

delete_book() {
    read -p "Enter book name to delete: " bookName
    for i in "${!books[@]}"; do
        if [[ "${books[$i]}" == "$bookName" ]]; then
            unset 'books[i]'
            unset 'bookCopies[$bookName]'
            echo -e "${GREEN}Book deleted successfully!${NC}"
            view_books
            return
        fi
    done
    echo -e "${RED}Book not found!${NC}"
    manage_books
}

search_book() {
    read -p "Enter book name to search: " bookName
    if [[ -v bookCopies["$bookName"] ]]; then
        echo -e "${GREEN}$bookName found with ${bookCopies[$bookName]} copies available.${NC}"
    else
        echo -e "${RED}Book not found!${NC}"
    fi
    manage_books
}

view_books() {
    echo -e "${CYAN}Books list:${NC}"
    for book in "${books[@]}"; do
        echo -e "${YELLOW}Book:${NC} $book, ${CYAN}Copies Available:${NC} ${bookCopies[$book]}"
    done

    # Display issued books with student and return date details
    echo -e "\n${CYAN}Issued Books:${NC}"
    for regNo in "${!studentsBooks[@]}"; do
        bookIssued=${studentsBooks[$regNo]}
        returnDate=${studentsReturnDates[$regNo]}
        echo -e "${YELLOW}Book Title:${NC} $bookIssued | ${YELLOW}Issued To:${NC} $regNo | ${YELLOW}Return Date:${NC} $returnDate"
    done

    manage_books

}

# Define the return_book function
return_book() {
    read -p "Enter student registration number: " regNo
    if [[ -n "${studentsBooks[$regNo]}" ]]; then
        # Check if the return is late
        currentDate=$(date +"%Y-%m-%d")
        dueDate="${studentsReturnDates[$regNo]}"
        
        # Calculate the difference in days between the current date and the due date
        overdueDays=$(( ( $(date -d "$currentDate" +%s) - $(date -d "$dueDate" +%s) ) / 86400 ))

        # If overdueDays is positive, apply a penalty
        if (( overdueDays > 0 )); then
            penalty=$(( overdueDays * dailyPenalty ))
            echo -e "${RED}Return is late by $overdueDays days. Penalty: $penalty.${NC}"
        else
            echo -e "${GREEN}Book returned on time. No penalty applied.${NC}"
        fi

        # Clear book and return date for the student
        unset 'studentsBooks[$regNo]'
        unset 'studentsReturnDates[$regNo]'
        echo -e "${GREEN}Book returned successfully!${NC}"
    else
        echo -e "${RED}No book issued to this student.${NC}"
    fi

    manage_books

}

# Function to issue a book
issue_book() {
    read -p "Enter book name to issue: " bookName
    if [[ -v bookCopies["$bookName"] ]]; then
        if [[ ${bookCopies[$bookName]} -gt 0 ]]; then
            read -p "Enter student's name: " studentName
            read -p "Enter student's registration number: " regNo
            student_found=false
            for i in "${!studentsNames[@]}"; do
                if [[ "${studentsNames[i]}" == "$studentName" && "${studentsRegNo[i]}" == "$regNo" ]]; then
                    student_found=true
                    break
                fi
            done
            if [[ "$student_found" == true ]]; then
                # Decrement the book copy count
                ((bookCopies["$bookName"]--))

                # Record the issued book and return date for this student
                issueDate=$(date +"%Y-%m-%d")
                returnDate=$(date -d "$issueDate + 14 days" +"%Y-%m-%d")  # Example: 14-day borrowing period
                studentsBooks["$regNo"]="$bookName"
                studentsReturnDates["$regNo"]="$returnDate"

                echo -e "${GREEN}$bookName issued to $studentName ($regNo). Copies left: ${bookCopies[$bookName]}${NC}"
                echo -e "${CYAN}Return Date:${NC} $returnDate"
            else
                echo -e "${RED}Student not found or registration number does not match!${NC}"
            fi
        else
            echo -e "${RED}Book not available or out of stock!${NC}"
        fi
    else
        echo -e "${RED}Book not found in the library!${NC}"
    fi
    main_menu
}



# Manage Students
manage_students() {
    echo -e "${YELLOW}----------------Manage Students----------------${NC}"
    echo "1. Add Student"
    echo "2. Delete Student"
    echo "3. View Students"
    echo "4. Return to Main Menu"
    read -p "Please enter your choice: " choice
    case $choice in
        1) add_student ;;
        2) delete_student ;;
        3) view_students ;;
        4) main_menu ;;
        *) echo -e "${RED}Invalid choice!${NC}" ; manage_students ;;
    esac
}

add_student() {
    read -p "Enter student name: " studentName
    while true; do
        read -p "Enter student registration number: " regNo
        # Check if the registration number already exists
        id_exists=false
        for existingRegNo in "${studentsRegNo[@]}"; do
            if [[ "$existingRegNo" == "$regNo" ]]; then
                echo -e "${RED}This registration number already exists. Please enter a different ID.${NC}"
                id_exists=true
                break
            fi
        done

        # If the ID is unique, exit the loop
        if [[ "$id_exists" == false ]]; then
            break
        fi
    done

    read -p "Enter student department: " department
    studentsNames+=("$studentName")
    studentsRegNo+=("$regNo")
    studentsDep+=("$department")
    echo -e "${GREEN}Student added successfully!${NC}"
    view_students
}


delete_student() {
    read -p "Enter student registration number to delete: " regNo
    for i in "${!studentsRegNo[@]}"; do
        if [[ "${studentsRegNo[$i]}" == "$regNo" ]]; then
            unset 'studentsNames[i]'
            unset 'studentsRegNo[i]'
            unset 'studentsDep[i]'
            echo -e "${GREEN}Student deleted successfully!${NC}"
            view_students
            return
        fi
    done
    echo -e "${RED}Student not found!${NC}"
    manage_students
}


# view_students function to show issued books and return dates
view_students() {
    echo -e "${CYAN}Students list:${NC}"
    for i in "${!studentsNames[@]}"; do
        echo -e "${YELLOW}Student $((i+1)):${NC} ${studentsNames[i]}, ${studentsRegNo[i]}, ${studentsDep[i]}"
        if [[ -n "${studentsBooks[${studentsRegNo[i]}]}" ]]; then
            echo -e "    Book Issued: ${studentsBooks[${studentsRegNo[i]}]}, Return Date: ${studentsReturnDates[${studentsRegNo[i]}]}"
        else
            echo -e "    No books issued."
        fi
    done
    manage_students
}

# Start with admin login
admin_login

