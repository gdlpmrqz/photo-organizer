# Photo Organizer (offline, large print)

A single Windows 10 batch file that sorts the photos and videos in its own folder into `Year\MM-MonthName\` folders and builds easy-to-read pages showing where each vacation was. Made for a computer with no internet connection.

## Use

1. Copy `organize-photos.bat` into the folder that holds the photos.
2. Double-click it and answer `Y` when asked.
3. Open `Start Here.html` (made in the same folder), then click a year.

## What it does

- Scans the folder and all subfolders for images (jpg, png, heic, tiff, raw, and more) and videos (mp4, mov, avi, and more).
- Date used: the date taken from the photo's metadata. If there is none, the earlier of the file's created and modified dates.
- Moves each file to `Year\MM-MonthName\` (for example `2023\07-July\IMG_0412.jpg`). Name clashes get a ` (1)` suffix instead of overwriting.
- Writes `Photos-YEAR.html` in each year folder. It uses very large text, with a "Where we went in 2023" summary at the top, then each month with the place name and its photos. Click a photo to open it full size.
- Writes `Start Here.html` in the main folder with a grid of year buttons and, below it, a random photo taken in the current month in any year, with a "Show another photo" button. If no photo was taken in the current month, it picks from all photos.
- Converts iPhone photos (HEIC/HEIF) to JPG so they show in the pages and open everywhere. The JPG goes into `Year\MM-MonthName\`, and the original HEIC is moved to `Originals Backup\Year\MM-MonthName\`. `Start Here.html` links to the backup folder.
- Safe to run again after adding more photos: only files outside the `Year\Month` folders are processed. Photos that were already organized are never moved, renamed or changed, and a new file with the same name as an old one gets a ` (1)` suffix instead of replacing it. Only the HTML pages are rebuilt.
- One-time fix for HEIC files that were organized by an older version of the script: set `$ConvertOldHeic = $true` near the top, run it once, then set it back to `$false`.
- Removes any folders left empty by the move (folders starting with a dot, such as `.git`, are never touched).
- Saves `organize-log-<timestamp>.csv` listing every move (From, To, Backup) so it can be reversed. Removed empty folders are not logged and would need to be recreated by hand when undoing.

## Place names without internet

The script has a built-in list of about 300 cities, national parks and popular vacation spots (United States, Canada, Mexico, the Caribbean, Europe, Asia and more). Each photo's GPS position is matched to the closest entry:

- within 40 km: the place name, for example `Key West, Florida`
- 40 to 200 km: `Near <place name>`
- farther than that: `A place we could not name`

Places not in the list are shown as the nearest listed place, so small towns may appear as "Near <bigger city>". To add places, add a line to the list near the top of the script in the form `Name|latitude|longitude`.

## Notes

- Uses the PowerShell that ships with Windows 10. Nothing to install and no internet needed.
- Location data only exists if the camera or phone saved GPS in the photo. Video and raw files are sorted by file date and show "Place not saved".
- Converting HEIC needs two free Windows add-ons from the Microsoft Store: **HEIF Image Extensions** and **HEVC Video Extensions**. Install them once on a computer with internet. If they are missing, the script leaves the HEIC files where they are, says so at the end, and converts them the next time you run it. The script itself never needs internet.
- Only HEIC originals that were converted go to `Originals Backup`. To also keep a copy of every other photo, change `$BackupEveryOriginal = $false` to `$true` near the top of the script (uses extra disk space).
- Raw (dng, cr2, nef, arw) and tiff photos show as a "Photo (click to open)" tile because web browsers cannot display them.
- Re-running is safe: files already in `Year\Month` folders are left alone, and the pages are rebuilt to include new photos.

## Uploading to GitHub

Double-click `git-sync.bat` in this folder for a simple menu: save and upload your changes, download the latest, see what changed, or view recent history. It asks for a short description of your changes, pulls first so GitHub's changes are merged in, and walks you through a conflict if the same file changed in both places. It needs Git for Windows and an internet connection.
