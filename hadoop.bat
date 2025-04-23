@echo off
setlocal EnableDelayedExpansion

:: Define Hadoop vars
set "HADOOP_VERSION=3.4.1"
set "HADOOP_DIR=%USERPROFILE%\hadoop"
set "HADOOP_ARCHIVE=hadoop-%HADOOP_VERSION%.tar.gz"
set "HADOOP_URL=https://downloads.apache.org/hadoop/common/hadoop-%HADOOP_VERSION%/%HADOOP_ARCHIVE%"
set "JAVA_HOME=C:\Program Files\Java\jdk-11"

:: Check Java
if exist "%JAVA_HOME%\bin\java.exe" (
    echo Found Java 11 in %JAVA_HOME%
) else (
    echo Java 11 not found in %JAVA_HOME%
    echo Please install Java 11 and set JAVA_HOME before proceeding.
    pause
    exit /b 1
)

:: Check tar
where tar >nul 2>&1
if errorlevel 1 (
    echo [ERROR] tar command not found. Please ensure tar is available in PATH.
    pause
    exit /b 1
)

:: Check curl
where curl >nul 2>&1
if errorlevel 1 (
    echo [ERROR] curl not found. Please ensure curl is installed.
    pause
    exit /b 1
)

:: Check if Hadoop already installed
if exist "%HADOOP_DIR%" (
    echo Hadoop is already installed at %HADOOP_DIR%
    goto :ENV_SETUP
)

:: Set script directory
set "SCRIPT_DIR=%~dp0"

:: Check if archive already exists
if exist "%SCRIPT_DIR%%HADOOP_ARCHIVE%" (
    echo Hadoop archive already exists. Skipping download.
) else (
    echo Downloading Hadoop %HADOOP_VERSION%...
    curl -L -o "%SCRIPT_DIR%%HADOOP_ARCHIVE%" "%HADOOP_URL%"
)

:: Extract Hadoop
echo Extracting Hadoop...
cd /d "%SCRIPT_DIR%"
powershell -Command "tar -xzf '%SCRIPT_DIR%%HADOOP_ARCHIVE%'"
move "hadoop-%HADOOP_VERSION%" "%HADOOP_DIR%"

:ENV_SETUP
:: Set environment variables
echo Setting environment variables...

setx HADOOP_HOME "%HADOOP_DIR%"
setx JAVA_HOME "%JAVA_HOME%"
setx PATH "%HADOOP_DIR%\bin;%HADOOP_DIR%\sbin;%JAVA_HOME%\bin;%PATH%"

:: Update hadoop-env.cmd
powershell -Command "(Get-Content '%HADOOP_DIR%\etc\hadoop\hadoop-env.cmd') -replace 'REM set JAVA_HOME=.*', 'set JAVA_HOME=%JAVA_HOME%' | Set-Content '%HADOOP_DIR%\etc\hadoop\hadoop-env.cmd'"

:: Write config files
echo Creating Hadoop configuration...

cd /d "%HADOOP_DIR%\etc\hadoop"

:: core-site.xml
(
echo ^<configuration^>
echo   ^<property^>
echo     ^<name^>fs.defaultFS^</name^>
echo     ^<value^>hdfs://localhost:9000^</value^>
echo   ^</property^>
echo ^</configuration^>
) > core-site.xml

:: hdfs-site.xml
(
echo ^<configuration^>
echo   ^<property^>
echo     ^<name^>dfs.replication^</name^>
echo     ^<value^>1^</value^>
echo   ^</property^>
echo ^</configuration^>
) > hdfs-site.xml

:: mapred-site.xml
copy mapred-site.xml.template mapred-site.xml >nul
(
echo ^<configuration^>
echo   ^<property^>
echo     ^<name^>mapreduce.framework.name^</name^>
echo     ^<value^>yarn^</value^>
echo   ^</property^>
echo   ^<property^>
echo     ^<name^>mapreduce.application.classpath^</name^>
echo     ^<value^>%HADOOP_HOME%\share\hadoop\mapreduce\*;%HADOOP_HOME%\share\hadoop\mapreduce\lib\*^</value^>
echo   ^</property^>
echo ^</configuration^>
) > mapred-site.xml

:: yarn-site.xml
(
echo ^<configuration^>
echo   ^<property^>
echo     ^<name^>yarn.resourcemanager.hostname^</name^>
echo     ^<value^>localhost^</value^>
echo   ^</property^>
echo   ^<property^>
echo     ^<name^>yarn.nodemanager.aux-services^</name^>
echo     ^<value^>mapreduce_shuffle^</value^>
echo   ^</property^>
echo ^</configuration^>
) > yarn-site.xml

echo.
echo [DONE] Hadoop %HADOOP_VERSION% installed successfully in %HADOOP_DIR%
echo Next steps:
echo   1. Open a new terminal (so PATH applies)
echo   2. Run: hdfs namenode -format
echo   3. Start with: start-dfs.cmd && start-yarn.cmd
echo   4. Check with: jps
echo.

endlocal
pause
