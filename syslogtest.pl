#!/usr/bin/env perl

use Sys::Syslog qw(
                        :DEFAULT
                        setlogsock
                );

openlog('nfs_logger',"ndelay,nowait","local0");
syslog("info", "Testy.  1,2,3, testes...");
closelog();
