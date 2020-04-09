TITLE Hangman Console Game (hangman.asm)
; This program will load phrases from a text file to allow the user to play hangman in the console
; Author:  Sam Holzer
; Date:    December 11, 2018
INCLUDE Irvine32.inc

.data
; File I/O necessities
numberofphrases = 6              ; Hard coded from text file
BUFSIZE = 50 * numberofphrases   ; The max number of bytes to read from file; each phrase needs to be 50 bytes (with buffer to fill extra space)
filename BYTE "phrases.txt",0    ; New phrases can be added to the game by updating the text file
phrases BYTE BUFSIZE DUP (?)     ; Used to store all the phrases from the text file
filehandle HANDLE ?              ; References the file handle
; Used to manage the current game
choosen_phrase BYTE 50 DUP (0)   ; Used to store the randomly selected phrase for the game
guess_phrase BYTE 48 DUP (20)     ; This will store the users guess to check against actual phrase, filled with ' '
partial_phrase BYTE 48 DUP (0)   ; Fills in as user guesses, used to display the partial phrase to the screen
notinphrase BYTE 26 DUP (0)      ; Stores letters not found in the phrase to display on the side
alreadyguessed BYTE 26 DUP (0)   ; Stores letters already guessed for prompting user to enter a new letter
; Message prompts
guessprompt BYTE "Do you want to guess a letter (enter 1) or the complete phrase (enter 2)? ",0
enterletter BYTE "Please enter a letter: ",0
invalidinput BYTE "Please enter a valid option next time. ",0
phraseguessprompt BYTE "Please enter your guess for the full phrase: ",0
allguessedprompt BYTE "You've guessed all available letters! ",0
noguessesprompt BYTE "It looks like you have no more guesses. ",0
; Used to determine current hangman configuration 
incorrectguesses BYTE 0          ; When incorrect guesses total 7, the user loses the game
                                 ; Different iterations of the hangman image to be used when users guess incorrect letter (below)
hangman6 BYTE "	  _________",13,10,"	  |       |",13,10,"          |       @",13,10,"          |      /|\",13,10,"          |       |",13,10,"          |      / \",13,10,"   _______|___________________",13,10,"  /       |                  /|",13,10," /                          / |",13,10,"/__________________________/  /",13,10,"|                          | /",13,10,"|__________________________|/",13,10,0
hangman5 BYTE "	  _________",13,10,"	  |       |",13,10,"          |       @",13,10,"          |      /|\",13,10,"          |       |",13,10,"          |      /",13,10,"   _______|___________________",13,10,"  /       |                  /|",13,10," /                          / |",13,10,"/__________________________/  /",13,10,"|                          | /",13,10,"|__________________________|/",13,10,0
hangman4 BYTE "	  _________",13,10,"	  |       |",13,10,"          |       @",13,10,"          |      /|\",13,10,"          |       |",13,10,"          |      ",13,10,"   _______|___________________",13,10,"  /       |                  /|",13,10," /                          / |",13,10,"/__________________________/  /",13,10,"|                          | /",13,10,"|__________________________|/",13,10,0
hangman3 BYTE "	  _________",13,10,"	  |       |",13,10,"          |       @",13,10,"          |      /|",13,10,"          |       |",13,10,"          |      ",13,10,"   _______|___________________",13,10,"  /       |                  /|",13,10," /                          / |",13,10,"/__________________________/  /",13,10,"|                          | /",13,10,"|__________________________|/",13,10,0
hangman2 BYTE "	  _________",13,10,"	  |       |",13,10,"          |       @",13,10,"          |       |",13,10,"          |       |",13,10,"          |      ",13,10,"   _______|___________________",13,10,"  /       |                  /|",13,10," /                          / |",13,10,"/__________________________/  /",13,10,"|                          | /",13,10,"|__________________________|/",13,10,0
hangman1 BYTE "	  _________",13,10,"	  |       |",13,10,"          |       @",13,10,"          |      ",13,10,"          |       ",13,10,"          |      ",13,10,"   _______|___________________",13,10,"  /       |                  /|",13,10," /                          / |",13,10,"/__________________________/  /",13,10,"|                          | /",13,10,"|__________________________|/",13,10,0
hangman0 BYTE "	  _________",10,"	  |       |",10,"          |       ",10,"          |      ",10,"          |       ",13,10,"          |      ",13,10,"   _______|___________________",13,10,"  /       |                  /|",13,10," /                          / |",13,10,"/__________________________/  /",13,10,"|                          | /",13,10,"|__________________________|/",13,10,0
; For a game lose
loseprompt BYTE "You have guessed incorrectly. You lose the game.",0
; For a game win
winprompt BYTE "You have guessed correctly. You win the Game!",0
.code
main PROC
    ; Open the phrases file, populate the storage array, and select random phrase
    ; 1. Open the file and store the handle
    mov edx,OFFSET filename
    call OpenInputFile
    mov filehandle,eax

    ; 2. Access the strings from the text file and store in array (phrases)
    mov edx,OFFSET phrases
    mov ecx, BUFSIZE
    call ReadFromFile

    ; 3. Select one phrase at random, store in array (choosen_phrase)
    call Randomize
    mov eax,numberofphrases      ; Used to select one of the phrases at random
    call RandomRange             ; eax = { 0 , numberofphrases-1 }
    mov ecx,50                   ; Loops through each of the 50 possible characters in the phrase to copy
    mul ecx                      ; Start index of the randomly selected phrase in eax: 0, 50, 100, 150, 200, or 250 etc.
    mov esi,0                    ; Index in the choosen_phrase array
    xor ebx,ebx                  ; Used to transfer from phrases to choosen_phrase
    L1:
        mov bl,phrases[eax+esi]     ; skip to the correct phrase (eax) and iterate to the next byte (esi)
        mov choosen_phrase[esi],bl  
        inc esi
    loop L1

    INVOKE Str_trim, ADDR choosen_phrase, ' '   ; Removes the buffer spaces at the end of the phrase

    xor eax,eax
    ; Here is where the game actually begins!
    Game:
        ; Need to determine the hangman state to print to the screen and if user has lost the game
        movzx eax,incorrectguesses
        cmp al,0
        jnz check1
        mov edx,OFFSET hangman0             ; No incorrect guesses, no body parts
        jmp guesstype
    check1:
        cmp al,1
        jnz check2
        mov edx,OFFSET hangman1             ; 1 incorrect guess, hangman with head
        jmp guesstype
    check2:
        cmp al,2
        jnz check3
        mov edx,OFFSET hangman2             ; 2 incorrect guesses, hangman with head and body
        jmp guesstype
    check3:
        cmp al,3
        jnz check4
        mov edx,OFFSET hangman3             ; 3 incorrect guesses, hangman with head, body, and left arm
        jmp guesstype
    check4:
        cmp al,4
        jnz check5
        mov edx,OFFSET hangman4             ; 4 incorrect guesses, hangman with head, body, and arms
        jmp guesstype
    check5:
        cmp al,5
        jnz check6
        mov edx,OFFSET hangman5             ; 5 incorrect guesses, hangman with head, body, arms, and left leg
        jmp guesstype
    check6:
        mov edx,OFFSET hangman6             ; 6 incorrect guess, full hangman and no more "lives"
        jmp guesstype                       ; Continue to prompt where user won't be able to guess

    guesstype:
        mov esi,OFFSET choosen_phrase       ; Used to calculate spacing of blanks for letters to guess
        mov ebx,OFFSET partial_phrase       ; Used to show where the user's previous guesses go
        push OFFSET noguessesprompt         ; Push the catch message for if user has no more guesses
        call PromptUser                     ; Output image and check whether user wants to guess letter or phrase
        cmp al,0                            ; User has no guesses left, so they lose
        jz lose                              
        ; al == 1 or 2 from the PromptUser subroutine, determine the right action based on guess request
    promptforletter:
        cmp al,1                            ; Check option
        jnz promptforphrase                 ; Not equal, user wants to guess phrase

        push OFFSET allguessedprompt        ; Set up the catch message
        push OFFSET enterletter             ; Set up the prompt
        push OFFSET alreadyguessed          ; Need to check if the user already guessed the letter
        push OFFSET partial_phrase          ; Will be added to if the user gets a correct guess
        push OFFSET choosen_phrase          ; Used to check if letters match the choosen_phrase
        call GuessLetter                    ; Get the users input for a letter to guess

        cmp al,1                            ; Did user guessed correctly? Don't take away life if true
        jz Game                        ; Can skip incrementing the incorrect count
        mov al,incorrectguesses             ; Need to increment the incorrect count
        inc al
        mov incorrectguesses,al
        jmp Game                       ; Reset state machine
    promptforphrase:
        mov edx,OFFSET phraseguessprompt    ; Set up the prompt
        mov esi,OFFSET choosen_phrase       ; Set up the phrase to be accesed by the subroutine
        mov ebx,OFFSET guess_phrase         ; Set up the user's guess for the subroutine
        call GuessPhrase
        cmp al,0                            ; Did the user win?
        jz win                              ; Skip over the lose block, otherwise, carry through

        ; User either wins or loses the game
    lose:
        call Clrscr                         ; New screen for game over
        mov edx,OFFSET loseprompt           
        call WriteString                    ; Let the user know that they have lost the game
        call Crlf
        jmp EndGame                         ; Quit the game
    win:
        call Clrscr                         ; New screen for game win                          
        mov edx,OFFSET winprompt           
        call WriteString                    ; Let the user know that they have won the game
        call Crlf
    EndGame:
        mov eax,2000                        ; Let user see if they won or lost, then close
        call Delay
exit
main ENDP

;----------------------------------------------------------------------------------------------
PromptUser PROC, nomore_prompt:PTR BYTE
; This subroutine handles user input by:
;   *Loading the blanks and already guessed letters to the console for the user to guess from
;   *Showing the user how many lives they have with the hangman image
;   *Prompting user for input (guessing a letter or phrase) and ensuring it's valid
;
; Receives:     *Address of the choosen_phrase (esi)
;               *Address of the user's partially completed phrase (ebx)
;               *Number of incorrect guesses (eax)
;
; Returns:      *Option to guess letter (1) or phrase (2) or if they have no more guesses (0) (al)        
;-----------------------------------------------------------------------------------------------
    call Clrscr                  ; Removes screen scrolling as user keeps guessing
    call WriteString             ; Writes the hangman image to the screen, set by the state machine
    call Crlf

    ; Make sure the user still has guesses left
    cmp al,6                     ; 6 is the point when the game is over (starts at 0)
    jb stillhaveguesses          ; Good to go, there are still remaining guesses
    mov edx,nomore_prompt        ; Tell user they have no more guesses
    call WriteString
    call WaitMsg
    mov eax,0                    ; Return 0 to tell main to go to the lose game page
    jmp validchoice              ; Skip to end
    
    stillhaveguesses:
    xor eax,eax                  ; Al will be used to check each index for spaces, letters, and blanks
    mov ecx,48                   ; Last two letters of the 50 space buffer are reserved for 0Ah and 0Dh (next line of text file)   
    ; Prints underscores for each character, spaces for each space, and letters already guessed by the user
    L2:
        mov al,BYTE PTR [ebx]        ; Grab the indexed characters in the partial phrase
        cmp al,0                     ; Unguessed letters are 0s in the array
        jz notguessed
        call WriteChar
        jmp nextcharacter
    notguessed:
        mov al,BYTE PTR [esi]        ; Grab the indexed character of the phrase
        cmp al,32                    ; ASCII value for a space
        jnz notspace                 ; Don't print a _ for spaces in the phrase
        mov al,' '                   ; al = 32h meaning there is space
        call WriteChar               ; Prints ' ' if there is a space
        jmp nextcharacter            ; Get next character
    notspace:
        mov al,'_'                   ; A letter is found
        call WriteChar               ; Writes a _ for each letter in the phrase
    nextcharacter:
        inc esi                      ; Next character in the game's phrase
        inc ebx                      ; Next character in the partial phrase
    loop L2
    call Crlf

    ; Prompts the user if they want to guess a new letter or the whole phrase
    prompt:
        ; 1. Prompt user to enter 1 or 2 for a new letter or the whole phrase
        call Crlf
        mov edx,OFFSET guessprompt   ; Used to prompt the user the above message
        call WriteString             ; Prompts the user if they want to guess a letter
        call ReadDec
        jc invalid                   ; Blank entry or invalid input, repeat question
        call Crlf

        ; 2. Check if the user wants to guess a new letter
        cmp al,1                     ; Does the user want to guess a new letter?
        jnz notletter                ; Not 1, they don't want to guess letter or user error
        jmp validchoice              ; Valid choice (guess letter), jumps to ret statement

        ; 3. Check if the user wants to guess the whole phrase
    notletter:
        cmp al,2                     ; Does the user want to guess the whole phrase?
        jnz invalid                  ; Not 2, they have invalid input
        jmp validchoice              ; Valid choice (guess phrase), jumps to the ret statement

        ; 4. User entered incorrectly, repeat the prompt
    invalid:
        mov edx,OFFSET invalidinput
        call WriteString
        call WaitMsg
        jmp prompt
    validchoice:
ret
PromptUser ENDP

;---------------------------------------------------------------------------------------------------------------------------------------------
GuessLetter PROC, choosen_array:PTR BYTE, partial_array:PTR BYTE, prevguess_array:PTR BYTE, letter_prompt:PTR BYTE, allguessed_prompt:PTR BYTE
; This subroutine allows the user to guess a new letter by:
;   *Prompting the user to enter a letter
;   *Making sure the letter entered has not been guessed before
;   *Checking if the phrase contains the guessed letter
;
; Receives:     *Address of the choosen_phrase
;               *Address of the user's partially completed phrase
;               *Address of the alreadyguessed array
;               *Address of letter enter prompt
;
; Returns:      *Correct (1) or incorrect guess (0) (al)   
;---------------------------------------------------------------------------------------------------------------------------------------------
    ; 0. Make sure the user hasn't guessed all letters
    mov esi,prevguess_array          ; Get the last value in the array of previous guesses
    cmp BYTE PTR [esi+25],0          ; Make sure the last value has not been set
    jnz allguessed                   ; If zf not set, user has guessed all letters, so skip prompt

    ; 1. Prompt user for letter
    inputletter:
        mov edx,letter_prompt
        call WriteString             ; Prompt message
        call ReadChar                ; Get user input (al)
        call WriteChar               ; Echo keypress to screen
        call Crlf

    ; 2.a Check that the letter is a valid key
    checkletter:
        cmp al,97                    ; Dec value for 'a'
        jb inputletter               ; Below 'a', so not a letter
        cmp al,122                   ; Dec value for 'z'
        ja inputletter               ; Above 'z', so not a letter

    ; 2.b Check that the letter hasn't been guessed before
        mov ecx,26                   ; Loop through until a 0 is found; can be max 26 letters long
    L1:
        cmp BYTE PTR [esi],0         ; If a zero has been found, we reached 'end' of the values. esi set at top of subroutine
        jz checkphrase               ; Done checking, skip to checking the phrase
        cmp al,[esi]                 ; Check to see if letter is in the index (already guessed)
        jz inputletter               ; The letter has already been guessed, user needs to input new letter
        inc esi                      ; Check next index on loop
    loop L1

    ; 3. Input is an unguessed letter, can check if it's in the phrase
    checkphrase:
        mov edx,0                    ; Clear so we know if user found a correct value or not
        mov [esi],al                 ; Store the letter in the alreadyguessed array for later
        mov esi,choosen_array        ; Checking through the game's phrase
        mov ebx,partial_array        ; Set the user's partial array if there is a match
        mov ecx,48                   ; Loop through each location; phrases have max of 48 characters
    L2:
        cmp al,[esi]                 ; Check if the index contains the right letter
        jnz nextletter               ; Not a match at this index of the phrase
        setz dl                      ; Correct letter found, won't make user lose a life
        mov [ebx],al                 ; Matched indexes will be stored in the partial array
    nextletter:
        inc esi                      ; Next index of the game's phrase
        inc ebx                      ; Next index of the user's partially guessed phrase
    loop L2
        mov eax,edx                  ; Set up return value (0 = incorrect guess, 1 = correct guess)
        jmp endguess                 ; Skip over the catch for user guessing all letters
    allguessed:
        mov al,1                     ; Make sure the user doesn't lose a life
        mov edx,allguessed_prompt    ; Let user know they have guessed every available letter
        call WriteString
        call WaitMsg
    endguess:
    push eax
    mov eax,240
    call Delay
    pop eax
ret
GuessLetter ENDP

;-----------------------------------------------------------------------------------------------
GuessPhrase PROC
; This subroutine allows the user to guess the phrase by:
;   *Accepting user input
;   *Checking if the phrase matches the choosen_phrase
;
; Receives:     *Address of the choosen_phrase (esi)
;               *Address of the user's guessed phrase (ebx)
;               *Offset to the phrase guess prompt (edx)
;
; Returns:      *Correct guess(0) or incorrect guess(1) (al)   
;-----------------------------------------------------------------------------------------------
    ; 1. Get user's guess for the phrase
    call WriteString                 ; Give the message prompt
    mov edx,ebx                      ; Store the user's guess. Offset of guess_phrase as buffer
    mov ecx,49                       ; Size of input guess_phrase buffer + 1 to read all chars
    call ReadString                  ; Get user's input from console

    ; 2. Determine if the strings are a match
    mov ecx,48                       ; Need to check only real phrase characters
    mov dx,0                         ; Used to set if user is correct or not
    ; Loop through each character of the two phrases and check for matches
    L1:
        mov al,[esi]                 ; Get character from the game's phrase
        cmp al,' '                   ; Can ignore spaces since the user knows them and there is buffer at end of choosen_phrase
        jz checknext                 ; Move on to next character if there is a space
        cmp al,[ebx]                 ; Check to see if characters are equal between user's guess and game's phrase
        jz checknext                 ; Letters match so check next index
        setnz dl                     ; Indicate that there is an incorrect comparison (al = 1)
        jmp done                     ; Exit the subroutine
    checknext:
        inc esi                      ; Get the next character of the game's phrase
        inc ebx                      ; Get the next character of the user's guess
    loop L1                       
    done:
        mov ax,dx                    ; Return the state of correctness to the main loop
ret
GuessPhrase ENDP

end