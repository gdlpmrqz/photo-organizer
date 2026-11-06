@echo off
setlocal
title Photo Organizer - GitHub Sync
cd /d "%~dp0"
rem ------------------------------------------------------------------
rem  git-sync.bat
rem  A simple menu so you do not have to remember git commands.
rem  Keep this file in the project folder (the one that contains .git)
rem  and double-click it.
rem    1  Save my changes and upload   = add + commit + pull + push
rem    2  Download the latest          = pull
rem    3  Show what has changed        = status
rem    4  Show recent history          = log
rem ------------------------------------------------------------------

where git >nul 2>nul
if errorlevel 1 goto :nogit
git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 goto :norepo
set "BRANCH="
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%b"
if not defined BRANCH set "BRANCH=main"

:menu
cls
echo ==============================================================
echo   Photo Organizer - GitHub Sync
echo   Folder: %CD%
echo   Branch: %BRANCH%
echo ==============================================================
echo.
echo   1   Save my changes and upload to GitHub   (commit, pull, push)
echo   2   Download the latest from GitHub        (pull)
echo   3   Show what has changed                  (status)
echo   4   Show recent history                    (log)
echo   5   Quit
echo.
choice /c 12345 /n /m "Choose 1-5: "
if errorlevel 5 goto :end
if errorlevel 4 goto :history
if errorlevel 3 goto :status
if errorlevel 2 goto :pullonly
if errorlevel 1 goto :sync
goto :menu

:status
echo.
git status -sb
echo.
pause
goto :menu

:history
echo.
git log --oneline --graph --decorate -15
echo.
pause
goto :menu

rem ---------------- 1: save + upload ----------------
:sync
set "AFTER=push"
call :ensureidentity
echo.
git add -A
git diff --cached --quiet
if errorlevel 1 goto :commit
echo No new changes to save.
goto :getlatest

:commit
echo.
echo These changes will be saved:
git status -s
echo.
set "MSG="
set /p "MSG=Describe what you changed (press Enter for 'Update'): "
if not defined MSG set "MSG=Update"
set "MSG=%MSG:"='%"
git commit -m "%MSG%"
if errorlevel 1 goto :commitfail

:getlatest
echo.
echo Getting the latest from GitHub...
git pull --no-rebase --no-edit origin %BRANCH%
if errorlevel 1 goto :pullproblem

:push
echo.
echo Uploading to GitHub...
git push -u origin %BRANCH%
if errorlevel 1 goto :pushfail
echo.
echo All done. GitHub is up to date.
echo.
pause
goto :menu

rem ---------------- 2: download only ----------------
:pullonly
set "AFTER=menu"
echo.
echo Getting the latest from GitHub...
git pull --no-rebase --no-edit origin %BRANCH%
if errorlevel 1 goto :pullproblem
echo.
echo Done. You have the latest version.
echo.
pause
goto :menu

rem ---------------- problems ----------------
:pullproblem
set "CONFLICTS="
for /f "delims=" %%f in ('git diff --name-only --diff-filter=U') do set "CONFLICTS=1"
if not defined CONFLICTS goto :pullfail
echo.
echo The same file was changed here and on GitHub. Files in conflict:
git diff --name-only --diff-filter=U
echo.
echo   1   Keep MY version of those files
echo   2   Use the GITHUB version of those files
echo   3   Cancel the download and decide later
echo.
choice /c 123 /n /m "Choose 1-3: "
if errorlevel 3 goto :abortmerge
if errorlevel 2 goto :takegithub
if errorlevel 1 goto :keepmine
goto :menu

:keepmine
set "SIDE=ours"
for /f "delims=" %%f in ('git diff --name-only --diff-filter=U') do call :resolveone "%%f"
goto :finishmerge

:takegithub
set "SIDE=theirs"
for /f "delims=" %%f in ('git diff --name-only --diff-filter=U') do call :resolveone "%%f"
goto :finishmerge

:resolveone
if "%SIDE%"=="ours" (git checkout --ours -- "%~1") else (git checkout --theirs -- "%~1")
git add -- "%~1"
goto :eof

:finishmerge
git commit --no-edit
if errorlevel 1 goto :commitfail
echo.
echo Conflict resolved.
if "%AFTER%"=="push" goto :push
echo.
pause
goto :menu

:abortmerge
git merge --abort
echo.
echo Cancelled. Nothing was changed.
echo.
pause
goto :menu

:pullfail
echo.
echo Could not get the latest from GitHub.
echo   - Check that this computer is online.
echo   - If it mentions local changes, use option 1 first to save them.
echo   - Make sure the repository exists at the address below.
echo.
git remote -v
echo.
pause
goto :menu

:pushfail
echo.
echo The upload did not work.
echo   - If a sign-in window opened, sign in to your GitHub account and try again.
echo   - If it says rejected, choose option 2 first and then option 1 again.
echo   - Check that this computer is online.
echo.
pause
goto :menu

:commitfail
echo.
echo Git could not save the changes. Read the message above.
echo If it mentions a .lock file, close other git programs and try again.
echo.
pause
goto :menu

rem ---------------- first-time setup ----------------
:ensureidentity
set "GN="
set "GE="
for /f "delims=" %%n in ('git config user.name') do set "GN=%%n"
for /f "delims=" %%e in ('git config user.email') do set "GE=%%e"
if not defined GN goto :askname
if not defined GE goto :askemail
goto :eof

:askname
echo.
echo Git needs your name for the history (asked only once).
set "GN="
set /p "GN=Your name: "
if not defined GN goto :askname
set "GN=%GN:"=%"
git config user.name "%GN%"
if defined GE goto :eof

:askemail
set "GE="
set /p "GE=Your email: "
if not defined GE goto :askemail
set "GE=%GE:"=%"
git config user.email "%GE%"
goto :eof

:nogit
echo.
echo Git is not installed (or not found).
echo Install "Git for Windows" from git-scm.com, then run this file again.
echo.
pause
goto :end

:norepo
echo.
echo This folder is not a git repository.
echo Keep git-sync.bat in the project folder that contains the .git folder.
echo.
pause
goto :end

:end
endlocal
