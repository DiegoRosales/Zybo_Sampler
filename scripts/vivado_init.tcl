## This script must be sourced relative to the root of the repository
set board_files_dir "./board_files"
if { [file exists ${board_files_dir}] } {
    set board_files_full_path [file normalize ${board_files_dir}]
    puts "The board files location is ${board_files_full_path}"
    set_param board.repoPaths ${board_files_full_path}
} else {
    puts "I couldn't find the board files path. Please check that you're sourcing this script from the Root of the repository"
}

