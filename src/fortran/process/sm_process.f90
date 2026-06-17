program sm_process
    use, intrinsic :: iso_fortran_env, only: int64, real64
    implicit none

    character(len=1024) :: infile
    character(len=1024) :: processed_dir
    character(len=1024) :: summary_file
    character(len=262144) :: line
    character(len=256) :: token
    character(len=64) :: first_date
    character(len=64) :: first_time
    character(len=64) :: last_date
    character(len=64) :: last_time
    character(len=64) :: peak_date
    character(len=64) :: peak_time

    integer :: argc
    integer :: unit
    integer :: out_unit
    integer :: ios
    integer :: pos
    integer :: bad_values
    integer :: line_count

    integer(int64) :: sample_count
    integer(int64) :: row_sample_index

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
    real(real64) :: mean_db
    real(real64) :: current_freq
    real(real64) :: peak_freq
    real(real64) :: peak_row_start
    real(real64) :: peak_row_end
    real(real64) :: peak_power

    logical :: found
    logical :: have_data

    argc = command_argument_count()

    if (argc < 1 .or. argc > 2) then
        write(*,'(a)') 'Usage: sm-process <rtl_power_csv_file> [processed_dir]'
        stop 1
    end if

    call get_command_argument(1, infile)

    if (argc == 2) then
        call get_command_argument(2, processed_dir)
    else
        processed_dir = '/var/db/solar-monitor/processed'
    end if

    call make_summary_path(infile, processed_dir, summary_file)

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

    peak_power = -huge(peak_power)
    peak_freq = 0.0_real64
    peak_row_start = 0.0_real64
    peak_row_end = 0.0_real64

    first_date = ''
    first_time = ''
    last_date = ''
    last_time = ''
    peak_date = ''
    peak_time = ''

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

        row_sample_index = 0_int64

        do
            call next_token(line, pos, token, found)
            if (.not. found) exit

            read(token, *, iostat=ios) value

            if (ios /= 0) then
                bad_values = bad_values + 1
                cycle
            end if

            sample_count = sample_count + 1_int64
            row_sample_index = row_sample_index + 1_int64
            sum_db = sum_db + value

            current_freq = f_start + (real(row_sample_index, real64) - 0.5_real64) * bin_width

            if (value < min_db) min_db = value
            if (value > max_db) max_db = value

            if (value > peak_power) then
                peak_power = value
                peak_freq = current_freq
                peak_row_start = f_start
                peak_row_end = f_end
                peak_date = last_date
                peak_time = last_time
            end if

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

    mean_db = sum_db / real(sample_count, real64)

    call execute_command_line('mkdir -p ' // trim(processed_dir), exitstat=ios)

    if (ios /= 0) then
        write(*,'(a)') 'FAIL: could not create processed directory: ' // trim(processed_dir)
        stop 1
    end if

    open(newunit=out_unit, file=trim(summary_file), status='replace', action='write', iostat=ios)

    if (ios /= 0) then
        write(*,'(a)') 'FAIL: could not write summary file: ' // trim(summary_file)
        stop 1
    end if

    call write_summary(out_unit)

    close(out_unit)

    write(*,'(a)') 'solar-monitor process'
    write(*,'(a)') '====================='
    write(*,'(a)') ''
    write(*,'(a)') 'Input file: ' // trim(infile)
    write(*,'(a)') 'Summary file: ' // trim(summary_file)
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
    write(*,'(a,f10.2,a)') 'Mean power:    ', mean_db, ' dB'
    write(*,'(a)') ''
    write(*,'(a,f12.0,a)') 'Peak frequency: ', peak_freq, ' Hz'
    write(*,'(a,f10.2,a)') 'Peak power:     ', peak_power, ' dB'
    write(*,'(a,a,1x,a)') 'Peak timestamp: ', trim(peak_date), trim(peak_time)
    write(*,'(a,f12.0,a,f12.0,a)') 'Peak row span:  ', peak_row_start, ' - ', peak_row_end, ' Hz'
    write(*,'(a,i0)') 'Bad values: ', bad_values

contains

    subroutine write_summary(out_unit)
        integer, intent(in) :: out_unit

        write(out_unit,'(a)') 'input_file=' // trim(infile)
        write(out_unit,'(a,i0)') 'records=', line_count
        write(out_unit,'(a,i0)') 'power_samples=', sample_count
        write(out_unit,'(a,a,1x,a)') 'first_timestamp=', trim(first_date), trim(first_time)
        write(out_unit,'(a,a,1x,a)') 'last_timestamp=', trim(last_date), trim(last_time)
        write(out_unit,'(a,i0)') 'lowest_frequency_hz=', nint(min_freq, int64)
        write(out_unit,'(a,i0)') 'highest_frequency_hz=', nint(max_freq, int64)
        write(out_unit,'(a,f0.2)') 'bin_width_hz=', first_bin_width
        write(out_unit,'(a,f0.2)') 'minimum_power_db=', min_db
        write(out_unit,'(a,f0.2)') 'maximum_power_db=', max_db
        write(out_unit,'(a,f0.2)') 'mean_power_db=', mean_db
        write(out_unit,'(a,i0)') 'peak_frequency_hz=', nint(peak_freq, int64)
        write(out_unit,'(a,f0.2)') 'peak_power_db=', peak_power
        write(out_unit,'(a,a,1x,a)') 'peak_timestamp=', trim(peak_date), trim(peak_time)
        write(out_unit,'(a,i0)') 'peak_row_start_hz=', nint(peak_row_start, int64)
        write(out_unit,'(a,i0)') 'peak_row_end_hz=', nint(peak_row_end, int64)
        write(out_unit,'(a,i0)') 'bad_values=', bad_values
    end subroutine write_summary

    subroutine make_summary_path(input_path, out_dir, output_path)
        character(len=*), intent(in) :: input_path
        character(len=*), intent(in) :: out_dir
        character(len=*), intent(out) :: output_path

        character(len=1024) :: base
        integer :: i
        integer :: start_pos
        integer :: end_pos
        integer :: n

        n = len_trim(input_path)
        start_pos = 1

        do i = n, 1, -1
            if (input_path(i:i) == '/') then
                start_pos = i + 1
                exit
            end if
        end do

        base = input_path(start_pos:n)
        end_pos = len_trim(base)

        if (end_pos > 4) then
            if (base(end_pos-3:end_pos) == '.csv') then
                base = base(1:end_pos-4)
            end if
        end if

        output_path = trim(out_dir) // '/' // trim(base) // '.summary'
    end subroutine make_summary_path

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
