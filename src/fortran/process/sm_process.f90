program sm_process
    use, intrinsic :: iso_fortran_env, only: int64, real64
    implicit none

    character(len=1024) :: infile
    character(len=262144) :: line
    character(len=256) :: token
    character(len=64) :: first_date, first_time
    character(len=64) :: last_date, last_time
    integer :: argc
    integer :: unit
    integer :: ios
    integer :: pos
    integer :: bad_values
    integer :: line_count
    integer(int64) :: sample_count
    real(real64) :: f_start
    real(real64) :: f_end
    real(real64) :: bin_width
    real(real64) :: bins
    real(real64) :: min_freq
    real(real64) :: max_freq
    real(real64) :: first_bin_width
    real(real64) :: value
    real(real64) :: min_db
    real(real64) :: max_db
    real(real64) :: sum_db
    logical :: found
    logical :: have_data

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
    sample_count = 0_int64
    bad_values = 0
    sum_db = 0.0_real64
    min_db = huge(min_db)
    max_db = -huge(max_db)
    min_freq = huge(min_freq)
    max_freq = -huge(max_freq)
    first_bin_width = 0.0_real64
    first_date = ''
    first_time = ''
    last_date = ''
    last_time = ''
    have_data = .false.

    do
        read(unit, '(A)', iostat=ios) line
        if (ios /= 0) exit
        if (len_trim(line) == 0) cycle

        pos = 1

        call next_token(line, pos, token, found)
        if (.not. found) cycle

        if (line_count == 0) first_date = trim(token)
        last_date = trim(token)

        call next_token(line, pos, token, found)
        if (.not. found) cycle

        if (line_count == 0) first_time = trim(token)
        last_time = trim(token)

        call next_token(line, pos, token, found)
        if (.not. found) cycle
        read(token, *, iostat=ios) f_start
        if (ios /= 0) cycle

        call next_token(line, pos, token, found)
        if (.not. found) cycle
        read(token, *, iostat=ios) f_end
        if (ios /= 0) cycle

        call next_token(line, pos, token, found)
        if (.not. found) cycle
        read(token, *, iostat=ios) bin_width
        if (ios /= 0) cycle

        call next_token(line, pos, token, found)
        if (.not. found) cycle
        read(token, *, iostat=ios) bins
        if (ios /= 0) cycle

        line_count = line_count + 1

        if (line_count == 1) first_bin_width = bin_width

        if (f_start < min_freq) min_freq = f_start
        if (f_end > max_freq) max_freq = f_end

        do
            call next_token(line, pos, token, found)
            if (.not. found) exit

            read(token, *, iostat=ios) value

            if (ios /= 0) then
                bad_values = bad_values + 1
                cycle
            end if

            sample_count = sample_count + 1_int64
            sum_db = sum_db + value

            if (value < min_db) min_db = value
            if (value > max_db) max_db = value

            have_data = .true.
        end do
    end do

    close(unit)

    if (line_count == 0) then
        write(*,'(a)') 'FAIL: input file contains no readable rtl_power records: ' // trim(infile)
        stop 1
    end if

    if (.not. have_data) then
        write(*,'(a)') 'FAIL: no power samples found in input file: ' // trim(infile)
        stop 1
    end if

    write(*,'(a)') 'solar-monitor process'
    write(*,'(a)') '====================='
    write(*,'(a)') ''
    write(*,'(a)') 'Input file: ' // trim(infile)
    write(*,'(a,i0)') 'Records: ', line_count
    write(*,'(a,i0)') 'Power samples: ', sample_count
    write(*,'(a)') ''
    write(*,'(a,a,1x,a)') 'First timestamp: ', trim(first_date), trim(first_time)
    write(*,'(a,a,1x,a)') 'Last timestamp:  ', trim(last_date), trim(last_time)
    write(*,'(a)') ''
    write(*,'(a,f12.0,a)') 'Lowest frequency:  ', min_freq, ' Hz'
    write(*,'(a,f12.0,a)') 'Highest frequency: ', max_freq, ' Hz'
    write(*,'(a,f12.2,a)') 'Bin width:         ', first_bin_width, ' Hz'
    write(*,'(a)') ''
    write(*,'(a,f10.2,a)') 'Minimum power: ', min_db, ' dB'
    write(*,'(a,f10.2,a)') 'Maximum power: ', max_db, ' dB'
    write(*,'(a,f10.2,a)') 'Mean power:    ', sum_db / real(sample_count, real64), ' dB'
    write(*,'(a,i0)') 'Bad values: ', bad_values

contains

    subroutine next_token(str, pos, token, found)
        character(len=*), intent(in) :: str
        integer, intent(inout) :: pos
        character(len=*), intent(out) :: token
        logical, intent(out) :: found

        integer :: comma
        integer :: start_pos
        integer :: end_pos
        integer :: n

        token = ''
        found = .false.

        n = len_trim(str)

        if (pos > n) return

        start_pos = pos
        comma = index(str(pos:n), ',')

        if (comma == 0) then
            end_pos = n
            pos = n + 1
        else
            end_pos = pos + comma - 2
            pos = pos + comma
        end if

        if (end_pos < start_pos) then
            token = ''
        else
            token = adjustl(str(start_pos:end_pos))
        end if

        found = .true.
    end subroutine next_token

end program sm_process
