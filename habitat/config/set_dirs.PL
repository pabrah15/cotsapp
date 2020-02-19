# -----------------------------------------------------------------------------
# CONFIDENTIAL AND PROPRIETARY. COPYRIGHT (C) 2011 ALI Solutions Inc.
# This software code contains proprietary trade secrets of ALI Solutions Inc.
# and is also protected by U.S. and other copyright laws and applicable
# international treaties. Any use, compilation, modification, distribution,
# reproduction, performance, display, or disclosure ("Use") of this software
# code is subject to the terms and conditions of your written agreement with
# ALI Solutions Inc. If you do not have such an agreement, then any Use of this
# material is strictly prohibited. Unauthorized Use of this software code,
# or any portion of it, will result in civil liability and/or criminal penalties.
# By modifying this software code, you agree to assign any and all intellectual
# property rights related in any way to your modification to ALI Solutions Inc.
# pursuant to your written agreement with ALI Solutions Inc.
# -----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#
# SUBROUTINE: set_dirs_template.PL
#
# PARAMETERS: none
#
# DESCRIPTION: Customer specific configuration is done here.
#
#-----------------------------------------------------------------------------

sub set_dirs {

    require ("util.PL");
    require ("custom_score.PL");

    my $cthome = $ENV{CALLTECH_HOME};
    my $gendir = "$cthome/generate";
    unshift (@INC, "$cthome/lib");

    if (-e "$gendir/set_dirs_gen.PL" and -e "$gendir/calc_key_length.PL" and
        -e "$gendir/calc_key_start.PL" and -e "$gendir/set_mult_partitions.PL") {

       require ("set_dirs_gen.PL");
       set_dirs_gen();

       require ("calc_key_length.PL");
       &calc_key_length;                # sets $__PRIMARY_KEY_LENGTH__

       require ("calc_key_start.PL");
       &calc_key_start;  # sets $__DL_KEY_START__

       require ("set_mult_partitions.PL");
       &set_mult_partitions;
    }

    # compress commands (currently only used in scorecard building)
    $__COMPRESS_CMD__ = "bzip2";
    $__UNCOMPRESS_CMD__ = "bunzip2";
    $__COMPRESS_EXT__ = "bz2";

    # Set to the user that created the schema
    $__DB_USER_NAME__ = "calltech"; # used in sc_deploy.pl for clob db fields

    $__SHELL_PATH__ = '/bin/sh'; # Generated in start scripts

    # Prolific configuration

    $__PROLIFIC_ALG__ = 'PROB_RWN'; # valid types: 'PROB_RWN' or 'PROB_R'

    #-----------------------------------------------------------------------------
    #
    # Scorecard building section
    #
    #-----------------------------------------------------------------------------

    $__SC_AUTO_UPDATE__ = 0; # Turns auto update of sc models on/off (0 off).

    $SCORECARD_DIR = "$ENV{CALLTECH_BASE}/sc";

    $TEMP1SORT_DIR = "$ENV{CALLTECH_BASE}/TEMP1"; # location of <table>_FLAT files
    $TEMP2SORT_DIR = "$ENV{CALLTECH_BASE}/TEMP3"; # location of COMBINED.* files
    $TEMP3SORT_DIR = "$ENV{CALLTECH_BASE}/TEMP3"; # location of temp sort files

    $__SC_CUTOFF_DAYS__ = 30;
    $__SC_HIST_DAYS__   = 30; # Used in add_fly_chars.PL
                              # and middleload_template.PL

    $__SC_DATE_WINDOW__ = 14; # Number of days to dump in each sc file
                              # ex. if $__SC_DATE_WINDOW__ = 14 then,
                              #     dump 14 days of data in each
                              #     SCORE_FLAT, ACTIVITY_FLAT, etc.
                              # NOTE: Each date segment will be a seperate
                              # process. Try to align the numbr of date segments
                              # with the number of cpus.

    # Number of parallel processes to launch for sampling and building
    $__SC_NUM_PARALLEL_PROCS__ = 8;

    # Stop processing of sc building if the assignment process is active.
    # To manually halt the process create a SCORECARD_HALT file in the
    # SCORECARD_DIR directory.
    # 0 => no halting
    # 1 => halt for assignment
    # 2 => halt for assignment and activity
    # 3 => halt for assignment, activity, and pre-summary
    # 4 => halt for assignment, activity pre-summary, and re-summary
    # Note: May take several minutes to halt.
    $__SC_PROCESS_HALTING__ = 4;

    # Execute scorecard building processes

    $__SC_RUN_GENERATE__ = 1;    # Execute generation of sc building code.
    $__SC_RUN_FETCH_DATA__ = 1;  # Build COMBINED.<DATE> file(s) from DB tables.
    $__SC_RUN_DATA_SHRED__ = 1;  # Shred COMBINED.<DATE> files into sc/tp directories
    $__SC_RUN_SAMPLING__ = 1;    # Build base variable build.dat.base files.
    $__SC_RUN_BUILDING__ = 1;    # Run means/coarses, mosama, binary/trinary and
                                 # output build.dat and model files.
    $__SC_RUN_LOAD_DATA__ = 1;   # Load model data to Oracle tables; Generate calc_*'s.
    $__SC_RUN_DIAGNOSTICS__ = 1; # Executes FORTRAN codes, means, coarses, and freqs
                                 # for investigating model building output.

    $__REMOVE_TEMP_BUILD_FILES__ = 1; # Removes temp *.dat.* files if set to 1.
                                      # Used in sc_sample.pl.

    # Output diagnostic info in the assignment - calc_scores process (model vars, weights, etc.)
    # Will output a file called $RUNTIME_DIR/<dialer>/calc_scores.dat
    $OUTPUT_SC_DEPLOY_DEBUG = 0;

    # Only output for this scorecard and timeperiod
    $__DEBUG_SC = 2;
    $__DEBUG_TP = 5;

    $__SC_ARCHIVE = 1; # archive sc.tar file to archive dir 1(on)/0(off)
    $__SC_ARCHIVE_DIR = "$ENV{CALLTECH_HOME}/archive";

    # Configuration for email - used to send email on build error
    $__mail_error__ = 0;              # 1(on)/0(off)
    $__mail_type__ = 'sendmail';      # mutt/mailx/sendmail
    $__smtp_server__ = 'localhost';
    $__mail_list__ = 'calltech@ali.com';
    $__mail_user__ = 'calltech@ali.com';

    #-----------------------------------------------------------------------------
    #
    # End of scorecard building section
    #
    #-----------------------------------------------------------------------------

    #-----------------------------------------------------------------------------
    #
    # Assignment/Download Process
    #
    #-----------------------------------------------------------------------------

    # When no trigger file is avaialable or a file cannot be renamed set this
    # option to 1. Once the file has been transferred the process will sleep
    # and stat the file again to make sure the transfer completed successfully.
    # This is obviously not the preferred way to ensure file delivery.
    $__DL_CHECK_FILE_COMPLETION__ = 0;
    $__DL_CHECK_FILE_COMPLETION_WAIT_TIME__ = 30; # number of seconds to sleep

    # Sleep time in seconds between each ftp/dialer loop

    $__DL_FTP_WAIT_TIME__ = 60; # seconds

    # If running in daemon mode launch_assignment will run till the following
    # is true: now_minutes() > $__ASGCUTOFF__
    # If set to 1 launch assignment will keep processing that dialer until
    # the asg cutoff is reached.

    $__DL_DAEMON_MODE__ = 0;

    # Dynamic file filtering (local and remote):
    #  A beginning 's/' and ending '/' in the file name of
    #  %__PRIMARY_ACCT_FILE__ turns on the filtering feature.
    #  All files that pass the filter will be processed (as same site).
    #  The following example will get all rcvfile.raw ending
    #  in a 0-9:
    #     ex. %__PRIMARY_ACCT_FILE__ = ('dialer1', 's/rcvfile.raw.[0-9]$/'
    #  A trigger file will be used if %primary_acct_file_trigger file
    #  is defined for the correct dialer.

    # Mutiple file processing:
    # Processing multiple files per dialer must be configured
    # in the following manner: create a list of files, delimited by commas, with
    # no spaces. Each file will be processed in the order found in the list.
    # Only one trigger file can be used for each set of files.

    sub get_primary_acct_filename {
         %__PRIMARY_ACCT_FILE__ = ('{{cfg.devdialer.dialer11}}', '{{cfg.devdialer.rcvfileraw}}',
                             #     'dialer2', 'rcvfile1.raw,rcvfile2.raw', # multiple file ex.
                                   );
    }

	# CT-2384 Define country codes for each input file
	sub get_primary_acct_country {
		%primary_acct_country = ('{{cfg.devdialer.dialer1}}' => '',	# Blank defaults to US + Canada
								 #'dialer2' => 'M');	# M = Mexico
                         );
	}

    # If 1, the file will be checked for zero size.
    # If 0, the process will NOT check for zero size and accept the file as complete.
    sub get_primary_acct_file_check_zero_bytes {
        %primary_acct_file_check_zero_bytes = ('{{cfg.devdialer.dialer1}}', 1,
                                              # 'dialer2', 1,
                                               );
    }

	# CT-2431 14-Jul-2015 Secondary account file is now per-dialer
    # set secondary acct file name
	# blank = no secondary file for dialer
    %__SECONDARY_ACCT_FILE__ = ('{{cfg.devdialer.dialer11}}' => '');
                # => '', 'dialer2' => 'dlsecondary2.dat' );

    # FTP status array; "1" means that we ftp the file; "0" means that
    # it is provided. Launch_assignment.

    sub init_primary_acct_file_xfer_method_array {
         %primary_acct_file_xfer_method = ('{{cfg.devdialer.dialer1}}',  '0',
                                          #'dialer2',  '1',
                                          );
    }

    # If a trigger file name is defined for a dialer, we use it. If
    # not, we ignore that procedure. This is in launch_assignment as well.

    sub init_primary_acct_trigger_file_array {
        %primary_acct_file_trigger =  ('{{cfg.devdialer.dialer1}}', '{{cfg.devdialer.rcvfiletrig}}',
                                             # 'dialer2',  'rcvfile.trg',
                                        );
    }

    sub dnld_age {
       # Example of recycle logic:
       # if ($__RECYCLE__ && $__DAYOFWEEK__ == 1) {
       #   $__dnld_age__ = 24;
       # }
       $__dnld_age__ = 12;
    }

    # Uncompress files transfered from dialer that have been compressed.
    sub set_uncompress_download {
        %COMPRESSED_DOWNLOAD = ( '{{cfg.devdialer.dialer1}}', '0',
        );
    }

    #-----------------------------------------------------------------------------
    #
    # Activity/Upload Process
    #
    #-----------------------------------------------------------------------------

	# Activity process after midnight. Set 1 to confirm Activity process after midnight, else 0.
	# Default 1, Activity process after midnight.
	$ACT_MIDNIGHT = 1;

    # Recompute durations based on call result sequence (CARS). Average duration
    # will be calculated based on the sum of all calls in the interval below. The
    # duration will be applied to the highest priority call R first, then W,
    # then N.
    $__USE_CARS_DURATIONS__ = 0;      # turn on(1)/off(0)
    $__CARS_DURATION_INTERVAL__ = 60; # in mins.

    # Sleep time in seconds between each ftp/dialer loop
    $__UL_FTP_WAIT_TIME__ = 60; # seconds

    # Set $ACCTMASTACT_UPDATE =1 for updating ACCOUNT_MASTER table __DATA_1__ and __DATA_2__ fields
    # If no updates to ACCOUNT_MASTER are required, set $ACCTMASTACT_UPDATE = 0 (Default)
    $ACCTMASTACT_UPDATE=0; # Allowed values 0 and 1 only

    # Activity file arrays. Utilized in launch_upload_parallel.PL RESULT_LOOP.
    # (these are possible activity filenames to look for on a per-dialer basis)
    # They're comma-separated and split out in launch_upload. Be sure to
    # put these in the order of priority that you want them examined, the
    # first filename being the highest priority.

    %activity_upload_filenames = (
                                    #'dialer1', 'statistics',
                                    '{{cfg.devdialer.dialer1}}', '{{cfg.devdialer.activityupldfile}}', # multi
                                 );

    # ftp (1) or not (0)?

    %activity_xfer_method = (
                               '{{cfg.devdialer.activitytrfr1}}',   '0',  # "Don't ftp" example
                               '{{cfg.devdialer.activitytrfr2}}',   '1',  # "Do ftp" example
                            );

    # If a trigger file name is defined for a dialer, we use it. If
    # not, we ignore that procedure.

    %activity_file_triggers = (
                                 '{{cfg.devdialer.activitytrig1}}',  '',                # No trigger
                                 '{{cfg.devdialer.activitytrig2}}',  'statistics.trg',
                              );

    sub act_age {
       $__act_age__ = 12;
    }

    #-----------------------------------------------------------------------------
    #
    # General configuration section
    #
    #-----------------------------------------------------------------------------

    # UTC Offset of CallTech Server
    #   PST or PDT (Pacific US)  => -8
    #   MST or MDT (Mountain US) => -7
    #   CST or CDT (Central US)  => -6
    #   EST or EDT (Eastern US)  => -5
    #   AST or ADT (Atlantic US) => -4
    #   BST or BDT (Country?)    => 0
    #   UTC 0 or GMT 0 => 0
    #   KST, KDT (Korea) => 8
    $__UTC_OFFSET__ = -6; # defaults to Central (-6)

    # Legal to call from 8 a.m. to this value
    $__LEGAL_CALLING_WINDOW__ = 13; # in hours

    # Generation on(1)/off(0) flag. Generation occurs at the end of the
    # re-summary process.
    $__GENERATE__ = 1;

    $__ARCHIVE_GENERATION__ = 1; # Archive generated config to arch/generation/generation.<date>

    # Log directory
    # The log file is rotated every time pre-summary is run.
    $__LOG_DIR__ = "$ENV{CALLTECH_HOME}/logs";

    # Number of parallel processes to launch for summary process
    $__NUM_PARALLEL_PROCS__ = 8;

    # Bulkload tables to Oracle -- asum, sak, prob, rsc, aux, and act
    $__LOAD_2_TABLES__ = 1;

    $PRODUCTION_DIR = "$ENV{CALLTECH_BASE}";

    # figure out runtime directory... (usually $HOME/PROD)
    $RUNTIME_DIR = "$PRODUCTION_DIR/PROD";

    # post processing for enhanced file.
    $__ENH_POSTPROCESS__ = 1; #Post processing option. 1 for pipe delimited, else for fixed-length,

    # place download/upload files into this directory as:
    #    <dialer>.<YYYYMMDD>.upload
    #    <dialer>.<YYYYMMDD>.download
    $BACKLOAD_DIR = "$PRODUCTION_DIR/backload";

    $BACKLOAD = 0; #backloading flag, 1 if running backloads; Also verify the $ACT_MIDNIGHT flag for backloading activity data

    # Run a local opt/asg FORTRAN process
    $__DO_LOCAL_ASG__ = 1; # Do NOT change this value

    # controls how many times we try to grab an activity (upload) file
    $__ACTRETRIES__ = 5;

    # controls how many times we try to grab a download file
    $__ASGRETRIES__ = 5;

    # Absolute time we quit waiting for download files (min. since midnight)
    # Sets $__ASGCUTOFF__ in launch_assignment.PL
    sub get_asg_cutoff {
       # return 660 if $__DAYOFWEEK__ == 0; # 11 a.m. on Sundays
       return 540; # 9 a.m.
    }

    # Absolute time we quit waiting for upload files (min. since midnight)
    sub get_act_cutoff {
       # return 240 if $__DAYOFWEEK__ == 0; # 4 a.m. on Sundays
       return 180; # 3 a.m.
    }

    # time in seconds, less 15 minutes, that activity file processing can
    # proceed until - will move on to next CT process after this time

    $__ACTCUTOFF_DATA_PROCESSING__ = 3600;

    $__ASGWAIT_CUTOFF__ = 2400; # 4 hours after last dnld

    $__ASG_LATECUTOFFEND__ = 420; # 7:00 am

    $__ASG_LATECUTOFFSTART__ = 345; # 5:45 am

    # controls if one process per dialer (parallel by dialer)
    $OPT_PARALLEL_DIALER = 1;

    # controls if one process per strategy (parallel by strat)
    $OPT_PARALLEL_STRAT = 0;

    # controls if we zero out probs for bad work phone number...
    $__BAD_WPHONE_ZERO__ = 0;

    # ...with this local start time to zero out right probs...
    $__BAD_WPHONE_START__ = 9;

    # ...and this local end time for the same
    $__BAD_WPHONE_END__ = 17;

    # controls if we zero out probs for bad home phone number....
    $__BAD_HPHONE_ZERO__ = 0;

    # ...with this local start time to zero out right probs...
    $__BAD_HPHONE_START__ = 17;

    # ...and this the local end time for the same.
    $__BAD_HPHONE_END__ = 21;

    # ..new recycling mechanism, with corresponding master flag
    $__RECYCLE_ENABLED__ = 1;

    $__EXCLUDE_RECYCLE_RPC__ = 1; # exclude right contacts if recycle day
    $__EXCLUDE_RECYCLE_PTP__ = 0; # exclude ptp accts if recycle day

    # ..to convert dos carriage returns to unix if needed
    # ..activity file current.<DIALER>
    $__CONVERT_CR__ = 0;

    sub convert_cr {
       # Ex. system ("dos2unix current.$__subdirs__[$i] temp");
       # Ex. system ("mv temp current.$__subdirs__[$i]");
       return 1;
    }

    # Flag to use alternate source of collector resources or not
    $__ALTERNATE_RESOURCES__ = 0;

    # Error alerts
    require ("alerts.PL");
    $DO_CUSTOM_ALERTS = 0; # do more than just log to LOGFILE

    # ..new date variables for setting runs to any date and time
    # update dates and set flag SET_DATE to 1 if want to use.
    # If flag is 1 then use OLD dates below,
    # If flag is 0 then use system dates.
    $SET_DATE = 0;
    $__OLDHOUR__ = '1';
    $__OLDDATE__ = '{{cfg.devdialer.OLDDATE}}';
    $__OLDDAY__ = '{{cfg.devdialer.OLDDAY}}';
    $__OLDDOM__ = '{{cfg.devdialer.OLDDOM}}';
    $__OLDDST__ = '0';
    $__OLDMIN__ = '0';

    # ..new flag for launching reports1.PL
    # set to 1 if want to use.

    $RUN_REPORTS = 1;

    # Reports note: remember to \ your special perl vars (\@), our put
    # it in single quotes.

    $REPORT_MAIL_SUBJECT_TEXT = "{{cfg.devdialer.MAILSUBJ}}";
    $REPORT_MAIL_LIST_TEXT = '{{cfg.devdialer.MAILLIST}}';

    $REPORT_MAIL_SUBJECT_ADMIN = "CallTech Admin Reports";
    $REPORT_MAIL_LIST_ADMIN = 'someone@company.com';

    $SEND_CONF = 0; # email out reports (if true, one of following must be set)
    $USE_MUTT = 0;
    $USE_MAILX = 0;
    $USE_SENDMAIL = 1;
    $SMTP_SERVER = "63.239.126.225";
    $REPORT_USER = "user\@alisolutions.com";

    $USE_ACT_DIALER = 0; # use activity dialer for shifting ct based variables.

    # Priority for account offset computation (see compute_timezone.PL).
    $PHONE_THEN_ZIP_FOR_OFFSET = 1; # 0 => zip then phone

    # Behavior for calling a record that does not have an associated time zone.
    $TIME_ZONE_FOR_DEFAULT = 0; # (0-Eastern, 1-Central, 2-Mountain, 3-Pacific)
    $START_TIME_FOR_DEFAULT = 12;
    $END_TIME_FOR_DEFAULT = 20;

    # Max load errors allowed for SQL Server bulk loading.
    $MAX_MSSQL_BULKLOAD_ERRORS = 10000;

    #-----------------------------------------------------------------------------
    #
    # Copyback configuration section
    #
    #-----------------------------------------------------------------------------

    # Set copyback flags for each dialer

    sub set_copyback_flag {
         %__LAUNCH_COPYBACK__ = (
                                '{{cfg.devdialer.dialer1}}', '{{cfg.devdialer.copyback_flag}}', # Don't copyback example
         );
    }

    # Name of enhanced file to copyback, if default <dialer>.raw
    # then leave it blank
    sub copyback_enhanced_name {
        %__ENHANCED_NAME__ =  (
                              '{{cfg.devdialer.dialer1}}',  '{{cfg.devdialer.dialer1}}.raw',
        );
    }

    # Name of enhanced trigger file to copyback. If not configured
    # no trigger file is sent.
    sub copyback_trigger_name {
        %__TRIGGER_NAME__ =  (
                 '{{cfg.devdialer.dialer1}}',  '{{cfg.devdialer.dialer1}}{{cfg.devdialer.copyback_trig_ext}}',
        );
    }

    # Use Unix compress to compress/uncompress files for dialers that can use it.
    sub set_compress_copyback {
        %COMPRESS_COPYBACK = (
                             '{{cfg.devdialer.dialer1}}',    '0',  # Don't compress enhanced file
                         #    'example',    '0',  # Don't compress enhanced file
         );
    }

    #-----------------------------------------------------------------------------
    #
    # End of copyback configuration section
    #
    #-----------------------------------------------------------------------------

    # Manipulate file flag for the header and footer
    # Strings for enhanced dl file
    $MAN_FILE_FLAG = 0;
    $HEADER = " ";
    $FOOTER = " ";

    sub output_dialer_record {
        return 1;
    }

    # Hashes to set ascii/ebcidic conversion.
    # API: Set to zero when no conversion is desired.
    # If the flag is set to 1, then the convert byte size (cbs) is NOT
    # used in the 'dd' command (ex. 'dd if=<infile> of=<outfile> conv=ascii').
    # If the flag is greater than 1 the flags value is used as the record size
    # (ex. 'dd if=<infile> of=<outfile> conv=ascii cbs=$convert_ul{'dialer1'}').
    sub init_ascii_ebcdic {
       %convert_ul = ('{{cfg.devdialer.dialer1}}', '0', # 0/1/<record length>
                     );
       %convert_dl = ('{{cfg.devdialer.dialer1}}', '0',
                     );
       %convert_cb = ('{{cfg.devdialer.dialer1}}', '0',
                     );
    } # end sub ascii_ebcdic

    # Strip off header(s) and footer(s),
    # or, add ...
    # Set to zero when no manipulation is desired
    sub init_header_trailer {
       %header_trailer_remove = ('{{cfg.devdialer.dialer1}}', '0',
                                );
       %header_trailer_add = ('{{cfg.devdialer.dialer1}}', '0',
                             );
    } # end sub ascii_ebcdic

    $CONVERT_NULLS_FLAG = 0;

    # to unzip
    $CONVERT_UL_FILE = 0;
    $CONVERT_DL_FILE = 0;
    $CONVERT_CURRENT_DL_FILE = 0; # convert all dl files as current.<dialer>

    sub convert_current_dl_file {
       my $dlFile = shift; # current.<dialer>
       return 1;
    }

    # kill one or more whitespace characters
    sub fan_out_generate {
      $OPERATOR =~ s/\s+//g;
      $STATUS =~ s/\s+//g;
      $CCR_NAME =~ s/\s+//g;
      return 1;
    }

    # kill one or more whitespace characters
    sub stripws { # $_[0] = var to manip
      my $var = $_[0];
      $var =~ s/\s+//g;
      return($var);
    }

    # take dl file and strip head/footer and add $LIST_NAME
    sub convert_dl_file {
      my $infile = $__look_for__ ;
      my $outfile = $__look_for__ . '.tmp';
      my @header = ();
      my @trailer = ();
      my @list_name = ();
      my $found = 0;
      my $currdir = $ENV{"PWD"};

      require("assignment_gen.PL");

      return if (! -e $infile);

      open(FILEH,"<$infile") || die "No open on download file:$infile\n";
      open(TABLE, ">$outfile") || die "No open on download temp file:$outfile\n";

      while($inline = <FILEH>) {
        if(substr($inline,0,8) =~ /-TRAILER/) {
          $found = 0;
        }
        if($found) {
          chomp($inline);
          print TABLE $inline;
          printf TABLE "%-15s\n", $header[1];
        }
        if(substr($inline,0,7) =~ /-HEADER/ ) {
          @header = split(' ', $inline);
          push(@list_name , $header[1]);
          $found = 1;
        }
      }
      close(FILEH);
      close(TABLE);

      rename $infile, $__look_for__ . '.old';  #'whirl.bak.1.old';
      rename $outfile, $infile;

      chdir($currdir);
    }

    ##
    # Pad the account number to PRIMARY_KEY_LENGTH
    #
    # CT-2100: By default this should be off, but it may be required, so the
    # code was left intact, and all copies of this code were changed to point
    # here. The code was then disabled (commented out).
    ##
    sub pad_account_number {
        my $ACCTNUM = shift;

        $ACCTNUM =~ s/\s+//g; # kill one or more whitespace characters

        ### BEGIN DISABLED CODE ###
        #if (length($ACCTNUM) < $__PRIMARY_KEY_LENGTH__) {
            # left-pad the string value of $__ACCTNUM w/ zeros
            # NOTE: we will be able to use the sprintf formatting in perl5, as in:
            # $__ACCTNUM = sprintf("%0${__PRIMARY_KEY_LENGTH__}s",
            #             $ACCTNUM);
            #
            # ...but perl4 makes that into spaces. So for now:
            #$ACCTNUM = ("0" x ($__PRIMARY_KEY_LENGTH__ - length($ACCTNUM))) . $ACCTNUM;
        #}
        ### END DISABLED CODE ###

        return ($ACCTNUM);
    } # end sub pad_account_number

    sub generate_dl {
       return 1;
    }

    sub write_aux_file {
       return 1;
    }

    sub rem_ht_dl_file {
       my $__look_for__ = shift;

       # Header and trailer numbers begin w/ zero to correspond
       # to Perl array positions

       log_file("Header/Trailer removal from download file invoked.");

       if ($header_trailer_add{$_[0]}) {
        log_file ("Header/Trailer counters will be added to end of download file.");
       }

       my $infile = $__look_for__;
       my $outfile = "$infile" . ".tmp";
       my (@header, @trailer) = ();
       my $header_number= -1;
       my $trailer_number= 0;
       my $direc = '';
       my $currdir = $ENV{"PWD"};
       my $obs = 0;

       require ("asignment_gen.PL");
       $direc = &download_directory;
       chdir ("$direc" . "/$_[0]");

       return if (! -e $infile);

       open (INFILE,"<$infile") || die "No open on download file:$infile\n";
       open (OUTFILE, ">$outfile") || die "No open on download temp file:$outfile\n";

       while ($inline = <INFILE>) {
          $obs++;

          if (substr($inline,0,8) eq "-TRAILER") {
             chomp($inline);
             push(@trailer, $inline);
             $trailer_number++;
          }
          elsif (substr($inline,0,7) eq "-HEADER") {
             chomp($inline);
             push(@header, $inline);
             $header_number++;
          }
          else {
             chomp($inline);
             print OUTFILE $inline;
             if ($obs == 1 && $header_number == -1) { # no headers yet
                log_file("NOTE:  Header/Trailer conversion of download file " .
                         "invoked, but file $infile does not contain a header.");
             }

             if ($header_trailer_add{$_[0]}) {
                if ($header_number == -1) { # no headers yet
                   printf OUTFILE "%-3s", '-1';
                   printf OUTFILE "%-3s\n", '-1';
                }
                else {
                   printf OUTFILE "%-3s", $header_number;
                   printf OUTFILE "%-3s\n", $trailer_number;
                }
             }
             else {
                print OUTFILE "\n"; # just set end of line if no ht prints
             }
          }
       } # end while loop

       close(INFILE);
       close(OUTFILE);

       rename $infile, $__look_for__ . ".ht" ;
       rename $outfile, $infile;

       chdir($currdir);
    } # end sub

} # end of sub set_dirs.PL

1;
