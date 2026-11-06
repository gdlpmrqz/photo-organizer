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
- Removes any folders left empty by the move (folders starting with a dot, such as `.git`, are never touched).
- Saves `organize-log-<timestamp>.csv` listing every move (From, To) so it can be reversed. Removed empty folders are not logged and would need to be recreated by hand when undoing.

## Place names without internet

The script has a built-in list of about 300 cities, national parks and popular vacation spots (United States, Canada, Mexico, the Caribbean, Europe, Asia and more). Each photo's GPS position is matched to the closest entry:

- within 40 km: the place name, for example `Key West, Florida`
- 40 to 200 km: `Near <place name>`
- farther than that: `A place we could not name`

Places not in the list are shown as the nearest listed place, so small towns may appear as "Near <bigger city>". To add places, add a line to the list near the top of the script in the form `Name|latitude|longitude`.

## Notes

- Uses the PowerShell that ships with Windows 10. Nothing to install and no internet needed.
- Location data only exists if the camera or phone saved GPS in the photo. HEIC, video and raw files are sorted by file date and show "Place not saved", because Windows' built-in image library cannot read their metadata. Phone photos that are JPG work best. Many Windows 10 browsers also cannot show HEIC thumbnails.
- Re-running is safe: files already in `Year\Month` folders are left alone, and the pages are rebuilt to include new photos.
