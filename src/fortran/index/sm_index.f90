program sm_index
    implicit none

    character(len=1024) :: summary_file
    character(len=1024) :: index_dir
    character(len=1024) :: index_file
    character(len=4096) :: line
    character(len=1024) :: key
    character(len=2048) :: value

    character(len=2048) :: first_timestamp
    character(len=2048) :: last_timestamp
    character(len=2048) :: mean_power_db
    character(len=2048) :: peak_frequency_hz
    character(len=2048) :: peak_power_db
    character(len=2048) :: bad_values

    integer :: argc
    integer :: unit
    integer :: out_unit
    integer :: ios

    logical :: have_first
    logical :: have_last
    logical :: have_mean
    logical :: have_peak_freq
    logical :: have_peak_power
    logical :: have_bad_values

    argc = command_argument_count()

    if (argc < 1 .or. argc > 2) then
        write(*,'(a)') 'Usage: sm-index <summary_file> [index_dir]'
        stop 1
    end if

    call get_command_argument(1, summary_file)

    if (argc == 2) then
        call get_command_argument(2, index_dir)
    else
        index_dir = '/var/db/solar-monitor/index'
    end if

    index_file = trim(index_dir) // '/latest.index'

    first_timestamp = ''
    last_timestamp = ''
    mean_power_db = ''
    peak_frequency_hz = ''
    peak_power_db = ''
    bad_values = ''

    have_first = .false.
    have_last = .false.
    have_mean = .false.
    have_peak_freq = .false.
    have_peak_power = .false.
    have_bad_values = .false.

    open(newunit=unit, file=trim(summary_file), status='old', action='read', iostat=ios)

    if (ios /= 0) then
        write(*,'(a)') 'FAIL: could not open summary file: ' // trim(summary_file)
        stop 1
    end if

    do
        read(unit, '(A)', iostat=ios) line
        if (ios /= 0) exit
        if (len_trim(line) == 0) cycle

        call split_key_value(line, key, value)

        select case (trim(key))
        case ('first_timestamp')
            first_timestamp = trim(value)
            have_first = .true.
        case ('last_timestamp')
            last_timestamp = trim(value)
            have_last = .true.
        case ('mean_power_db')
            mean_power_db = trim(value)
            have_mean = .true.
        case ('peak_frequency_hz')
            peak_frequency_hz = trim(value)
            have_peak_freq = .true.
        case ('peak_power_db')
            peak_power_db = trim(value)
            have_peak_power = .true.
        case ('bad_values')
            bad_values = trim(value)
            have_bad_values = .true.
        end select
    end do

    close(unit)

    if (.not. have_first) call missing_key('first_timestamp')
    if (.not. have_last) call missing_key('last_timestamp')
    if (.not. have_mean) call missing_key('mean_power_db')
    if (.not. have_peak_freq) call missing_key('peak_frequency_hz')
    if (.not. have_peak_power) call missing_key('peak_power_db')
    if (.not. have_bad_values) call missing_key('bad_values')

    call execute_command_line('mkdir -p ' // trim(index_dir), exitstat=ios)

    if (ios /= 0) then
        write(*,'(a)') 'FAIL: could not create index directory: ' // trim(index_dir)
        stop 1
    end if

    open(newunit=out_unit, file=trim(index_file), status='replace', action='write', iostat=ios)

    if (ios /= 0) then
        write(*,'(a)') 'FAIL: could not write index file: ' // trim(index_file)
        stop 1
    end if

    write(out_unit,'(a)') 'latest_summary=' // trim(summary_file)
    write(out_unit,'(a)') 'last_capture_start=' // trim(first_timestamp)
    write(out_unit,'(a)') 'last_capture_end=' // trim(last_timestamp)
    write(out_unit,'(a)') 'mean_power_db=' // trim(mean_power_db)
    write(out_unit,'(a)') 'peak_frequency_hz=' // trim(peak_frequency_hz)
    write(out_unit,'(a)') 'peak_power_db=' // trim(peak_power_db)
    write(out_unit,'(a)') 'bad_values=' // trim(bad_values)

    if (trim(bad_values) == '0') then
        write(out_unit,'(a)') 'status=ok'
    else
        write(out_unit,'(a)') 'status=warning'
    end if

    close(out_unit)

    write(*,'(a)') 'solar-monitor index'
    write(*,'(a)') '==================='
    write(*,'(a)') ''
    write(*,'(a)') 'Summary file: ' // trim(summary_file)
    write(*,'(a)') 'Index file:   ' // trim(index_file)
    write(*,'(a)') ''
    write(*,'(a)') 'Last capture: ' // trim(first_timestamp) // ' to ' // trim(last_timestamp)
    write(*,'(a)') 'Mean power:   ' // trim(mean_power_db) // ' dB'
    write(*,'(a)') 'Peak:         ' // trim(peak_frequency_hz) // ' Hz at ' // trim(peak_power_db) // ' dB'
    write(*,'(a)') 'Bad values:   ' // trim(bad_values)

contains

    subroutine split_key_value(str, key, value)
        character(len=*), intent(in) :: str
        character(len=*), intent(out) :: key
        character(len=*), intent(out) :: value

        integer :: eq

        key = ''
        value = ''

        eq = index(str, '=')

        if (eq <= 0) return

        key = adjustl(str(1:eq-1))
        value = adjustl(str(eq+1:len_trim(str)))
    end subroutine split_key_value

    subroutine missing_key(name)
        character(len=*), intent(in) :: name

        write(*,'(a)') 'FAIL: summary file missing required key: ' // trim(name)
        stop 1
    end subroutine missing_key

end program sm_index
