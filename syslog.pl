#!/usr/bin/env perl

use Sys::Syslog qw(
			:DEFAULT
			setlogsock
		);

openlog('nfs_logger',"ndelay,nowait","user");
syslog("info", "Testy.  1,2,3, testes...");
syslog("LOG_INFO", "Testy.  1,2,3, testes...");
closelog();
