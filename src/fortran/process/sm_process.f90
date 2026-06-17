program sm_process
    implicit none

    character(len=1024) :: infile
    character(len=4096) :: line
    character(len=4096) :: first_line
    character(len=4096) :: last_line
    integer :: argc
    integer :: unit
    integer :: ios
    integer :: line_count

    argc = command_argument_count()

    if (argc /= 1) then
        write(*,'(a)') 'Usage: sm-process <rtl_power_csv_file>'
        stop 1
    end if

    call get_command_argument(1, infile)

    open(newunit=unit, file=trim(infile), status='old', action='read', iostat=ios)

    if (ios /= 0) then
        write(*,'(a)') 'FAIL: could not open input file: ' // trim(infile)
        stop 1
    end if

    line_count = 0
    first_line = ''
    last_line = ''

    do
        read(unit, '(A)', iostat=ios) line

        if (ios /= 0) exit

        if (len_trim(line) == 0) cycle

        line_count = line_count + 1

        if (line_count == 1) then
            first_line = line
        end if

        last_line = line
    end do

    close(unit)

    if (line_count == 0) then
        write(*,'(a)') 'FAIL: input file contains no data lines: ' // trim(infile)
        stop 1
    end if

    write(*,'(a)') 'solar-monitor process'
    write(*,'(a)') '====================='
    write(*,'(a)') ''
    write(*,'(a)') 'Input file: ' // trim(infile)
    write(*,'(a,i0)') 'Data lines: ', line_count
    write(*,'(a)') ''
    write(*,'(a)') 'First record:'
    write(*,'(a)') trim(first_line)
    write(*,'(a)') ''
    write(*,'(a)') 'Last record:'
    write(*,'(a)') trim(last_line)

end program sm_process
