@echo off
setlocal
title Photo Organizer
rem ------------------------------------------------------------------
rem  organize-photos.bat   (works fully offline - no internet needed)
rem  Put this file in the folder with the photos and double-click it.
rem  It moves photos/videos (this folder and subfolders) into
rem      Year\MM-MonthName\file
rem  using the date taken, or the file's created date if there is none.
rem  Inside each year folder it writes a large-print page,
rem  Photos-YEAR.html, showing the NAME OF THE PLACE for each photo
rem  (worked out from the GPS location saved in the photo).
rem  A page called "Start Here.html" is also made in the main folder,
rem  with a button for each year and a random photo from this month.
rem  Folders left empty after the move are removed.
rem  iPhone photos (HEIC) are converted to JPG so they show in the pages.
rem  Photos already in Year\Month folders are left alone, so it is safe to
rem  add new photos to the folder and run this again.
rem  The original HEIC files are kept in the "Originals Backup" folder.
rem  A log of every move is saved so it can be undone.
rem ------------------------------------------------------------------
set "SELF=%~f0"
set "TARGET_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SELF); $i=$s.LastIndexOf('#'+'PS_START'); & ([scriptblock]::Create($s.Substring($i)))"
echo.
pause
exit /b
#PS_START
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
$inv  = [Globalization.CultureInfo]::InvariantCulture
$root = (Resolve-Path -LiteralPath $env:TARGET_DIR).ProviderPath.TrimEnd('\')

$imageExt = '.jpg','.jpeg','.png','.gif','.bmp','.tif','.tiff','.webp','.heic','.heif','.dng','.cr2','.nef','.arw'
$videoExt = '.mp4','.mov','.avi','.mkv','.m4v','.3gp','.wmv'
$mediaExt = $imageExt + $videoExt
$heicExt  = '.heic','.heif'

# ---- Settings ----
$backupName = 'Originals Backup'    # folder (inside the photo folder) that keeps the original files
$BackupEveryOriginal = $false       # $false = back up only the HEIC originals that get converted
                                    # $true  = also keep a copy of every other photo (uses extra disk space)
$ConvertOldHeic = $false            # $false = photos already in Year\Month folders are never touched
                                    # $true  = also convert HEIC photos already in Year\Month folders (one-time fix)
$exifExt  = '.jpg','.jpeg','.tif','.tiff','.png'

# ---- Built-in place list (name|latitude|longitude) so no internet is needed ----
$placeText = @'
New York City, New York|40.71|-74.01
Los Angeles, California|34.05|-118.24
San Diego, California|32.72|-117.16
San Francisco, California|37.77|-122.42
San Jose, California|37.34|-121.89
Sacramento, California|38.58|-121.49
Santa Barbara, California|34.42|-119.70
Monterey, California|36.60|-121.89
Yosemite National Park, California|37.87|-119.54
Lake Tahoe, California|39.10|-120.03
Palm Springs, California|33.83|-116.55
Disneyland, Anaheim, California|33.81|-117.92
Las Vegas, Nevada|36.17|-115.14
Reno, Nevada|39.53|-119.81
Phoenix, Arizona|33.45|-112.07
Tucson, Arizona|32.22|-110.97
Sedona, Arizona|34.87|-111.76
Grand Canyon, Arizona|36.11|-112.11
Flagstaff, Arizona|35.20|-111.65
Page, Arizona|36.91|-111.46
Albuquerque, New Mexico|35.08|-106.65
Santa Fe, New Mexico|35.69|-105.94
Salt Lake City, Utah|40.76|-111.89
Zion National Park, Utah|37.30|-113.03
Bryce Canyon, Utah|37.59|-112.19
Moab and Arches National Park, Utah|38.73|-109.59
Park City, Utah|40.65|-111.50
Denver, Colorado|39.74|-104.99
Colorado Springs, Colorado|38.83|-104.82
Rocky Mountain National Park, Colorado|40.34|-105.68
Aspen, Colorado|39.19|-106.82
Vail, Colorado|39.64|-106.37
Durango, Colorado|37.27|-107.88
Boulder, Colorado|40.01|-105.27
Fort Collins, Colorado|40.59|-105.08
Cheyenne, Wyoming|41.14|-104.82
Jackson Hole, Wyoming|43.48|-110.76
Yellowstone National Park, Wyoming|44.43|-110.59
Grand Teton National Park, Wyoming|43.79|-110.68
Billings, Montana|45.78|-108.50
Glacier National Park, Montana|48.76|-113.79
Missoula, Montana|46.87|-114.00
Boise, Idaho|43.62|-116.20
Sun Valley, Idaho|43.70|-114.35
Seattle, Washington|47.61|-122.33
Spokane, Washington|47.66|-117.43
Mount Rainier National Park, Washington|46.85|-121.76
Portland, Oregon|45.52|-122.68
Bend, Oregon|44.06|-121.31
Crater Lake, Oregon|42.94|-122.11
Cannon Beach, Oregon|45.89|-123.96
Anchorage, Alaska|61.22|-149.90
Juneau, Alaska|58.30|-134.42
Denali National Park, Alaska|63.33|-150.50
Honolulu, Hawaii|21.31|-157.86
Maui, Hawaii|20.80|-156.33
Kona, Hawaii|19.64|-155.99
Kauai, Hawaii|22.08|-159.50
Hilo, Hawaii|19.72|-155.09
Austin, Texas|30.27|-97.74
Dallas, Texas|32.78|-96.80
Houston, Texas|29.76|-95.37
San Antonio, Texas|29.42|-98.49
El Paso, Texas|31.76|-106.49
Galveston, Texas|29.30|-94.80
Oklahoma City, Oklahoma|35.47|-97.52
Tulsa, Oklahoma|36.15|-95.99
Kansas City, Missouri|39.10|-94.58
St. Louis, Missouri|38.63|-90.20
Branson, Missouri|36.64|-93.22
Omaha, Nebraska|41.26|-95.93
Wichita, Kansas|37.69|-97.34
Des Moines, Iowa|41.59|-93.62
Minneapolis, Minnesota|44.98|-93.27
Duluth, Minnesota|46.79|-92.10
Fargo, North Dakota|46.88|-96.79
Mount Rushmore, South Dakota|43.88|-103.46
Rapid City, South Dakota|44.08|-103.23
Sioux Falls, South Dakota|43.55|-96.73
Chicago, Illinois|41.88|-87.63
Milwaukee, Wisconsin|43.04|-87.91
Madison, Wisconsin|43.07|-89.40
Wisconsin Dells, Wisconsin|43.63|-89.77
Detroit, Michigan|42.33|-83.05
Grand Rapids, Michigan|42.96|-85.67
Mackinac Island, Michigan|45.85|-84.62
Indianapolis, Indiana|39.77|-86.16
Columbus, Ohio|39.96|-83.00
Cleveland, Ohio|41.50|-81.69
Cincinnati, Ohio|39.10|-84.51
Louisville, Kentucky|38.25|-85.76
Lexington, Kentucky|38.04|-84.50
Nashville, Tennessee|36.16|-86.78
Memphis, Tennessee|35.15|-90.05
Gatlinburg and the Great Smoky Mountains, Tennessee|35.71|-83.51
Knoxville, Tennessee|35.96|-83.92
Atlanta, Georgia|33.75|-84.39
Savannah, Georgia|32.08|-81.09
Charleston, South Carolina|32.78|-79.93
Myrtle Beach, South Carolina|33.69|-78.89
Charlotte, North Carolina|35.23|-80.84
Raleigh, North Carolina|35.78|-78.64
Asheville, North Carolina|35.60|-82.55
Outer Banks, North Carolina|35.56|-75.47
Virginia Beach, Virginia|36.85|-75.98
Richmond, Virginia|37.54|-77.44
Williamsburg, Virginia|37.27|-76.71
Shenandoah National Park, Virginia|38.53|-78.44
Washington, D.C.|38.91|-77.04
Baltimore, Maryland|39.29|-76.61
Ocean City, Maryland|38.34|-75.08
Philadelphia, Pennsylvania|39.95|-75.17
Pittsburgh, Pennsylvania|40.44|-80.00
Gettysburg, Pennsylvania|39.83|-77.23
Atlantic City, New Jersey|39.36|-74.42
Niagara Falls, New York|43.09|-79.06
Buffalo, New York|42.89|-78.88
Albany, New York|42.65|-73.76
Lake Placid and the Adirondacks, New York|44.28|-73.98
Boston, Massachusetts|42.36|-71.06
Cape Cod, Massachusetts|41.67|-70.00
Providence, Rhode Island|41.82|-71.41
Newport, Rhode Island|41.49|-71.31
Hartford, Connecticut|41.76|-72.68
Burlington, Vermont|44.48|-73.21
Portland, Maine|43.66|-70.26
Acadia National Park, Maine|44.34|-68.27
White Mountains, New Hampshire|44.27|-71.30
Miami, Florida|25.76|-80.19
Key West, Florida|24.56|-81.78
Fort Lauderdale, Florida|26.12|-80.14
Walt Disney World, Orlando, Florida|28.42|-81.58
Orlando, Florida|28.54|-81.38
Tampa, Florida|27.95|-82.46
St. Petersburg, Florida|27.77|-82.64
Clearwater Beach, Florida|27.98|-82.83
Jacksonville, Florida|30.33|-81.66
St. Augustine, Florida|29.90|-81.31
Daytona Beach, Florida|29.21|-81.02
Pensacola, Florida|30.42|-87.22
Panama City Beach, Florida|30.18|-85.80
Naples, Florida|26.14|-81.79
Fort Myers, Florida|26.64|-81.87
Sarasota, Florida|27.34|-82.53
Cape Canaveral, Florida|28.39|-80.60
New Orleans, Louisiana|29.95|-90.07
Baton Rouge, Louisiana|30.45|-91.15
Biloxi, Mississippi|30.40|-88.89
Mobile, Alabama|30.69|-88.04
Gulf Shores, Alabama|30.25|-87.70
Birmingham, Alabama|33.52|-86.80
Little Rock, Arkansas|34.75|-92.29
Hot Springs, Arkansas|34.50|-93.06
Vancouver, British Columbia, Canada|49.28|-123.12
Victoria, British Columbia, Canada|48.43|-123.37
Whistler, British Columbia, Canada|50.12|-122.95
Banff, Alberta, Canada|51.18|-115.57
Jasper, Alberta, Canada|52.87|-118.08
Calgary, Alberta, Canada|51.05|-114.07
Edmonton, Alberta, Canada|53.55|-113.49
Toronto, Ontario, Canada|43.65|-79.38
Ottawa, Ontario, Canada|45.42|-75.70
Niagara Falls, Ontario, Canada|43.09|-79.08
Montreal, Quebec, Canada|45.50|-73.57
Quebec City, Quebec, Canada|46.81|-71.21
Halifax, Nova Scotia, Canada|44.65|-63.57
Winnipeg, Manitoba, Canada|49.90|-97.14
Saskatoon, Saskatchewan, Canada|52.13|-106.67
Cancun, Mexico|21.16|-86.85
Playa del Carmen, Mexico|20.63|-87.07
Tulum, Mexico|20.21|-87.47
Cozumel, Mexico|20.42|-86.92
Mexico City, Mexico|19.43|-99.13
Cabo San Lucas, Mexico|22.89|-109.91
Puerto Vallarta, Mexico|20.65|-105.23
Guadalajara, Mexico|20.66|-103.35
Mazatlan, Mexico|23.25|-106.41
Acapulco, Mexico|16.85|-99.82
Oaxaca, Mexico|17.07|-96.73
Tijuana, Mexico|32.51|-117.04
Havana, Cuba|23.11|-82.37
Nassau, Bahamas|25.05|-77.35
San Juan, Puerto Rico|18.47|-66.11
Punta Cana, Dominican Republic|18.58|-68.41
Montego Bay, Jamaica|18.48|-77.92
Negril, Jamaica|18.27|-78.35
Grand Cayman, Cayman Islands|19.31|-81.25
Aruba|12.52|-70.03
Barbados|13.10|-59.61
St. Thomas, U.S. Virgin Islands|18.34|-64.93
Bermuda|32.30|-64.78
San Jose, Costa Rica|9.93|-84.08
Panama City, Panama|8.98|-79.52
Belize City, Belize|17.50|-88.20
London, England|51.51|-0.13
Edinburgh, Scotland|55.95|-3.19
Dublin, Ireland|53.35|-6.26
Paris, France|48.86|2.35
Nice, France|43.70|7.27
Lyon, France|45.76|4.84
Bordeaux, France|44.84|-0.58
Marseille, France|43.30|5.37
Normandy (Caen), France|49.18|-0.37
Barcelona, Spain|41.39|2.17
Madrid, Spain|40.42|-3.70
Seville, Spain|37.39|-5.98
Granada, Spain|37.18|-3.60
Valencia, Spain|39.47|-0.38
Malaga, Spain|36.72|-4.42
Palma de Mallorca, Spain|39.57|2.65
Lisbon, Portugal|38.72|-9.14
Porto, Portugal|41.15|-8.61
Rome, Italy|41.90|12.50
Florence, Italy|43.77|11.26
Venice, Italy|45.44|12.32
Milan, Italy|45.46|9.19
Naples, Italy|40.85|14.27
Amalfi Coast, Italy|40.63|14.60
Palermo, Sicily, Italy|38.12|13.36
Berlin, Germany|52.52|13.40
Munich, Germany|48.14|11.58
Frankfurt, Germany|50.11|8.68
Hamburg, Germany|53.55|9.99
Cologne, Germany|50.94|6.96
Amsterdam, Netherlands|52.37|4.90
Brussels, Belgium|50.85|4.35
Bruges, Belgium|51.21|3.22
Zurich, Switzerland|47.38|8.54
Geneva, Switzerland|46.20|6.14
Interlaken, Switzerland|46.69|7.86
Vienna, Austria|48.21|16.37
Salzburg, Austria|47.80|13.04
Prague, Czech Republic|50.08|14.44
Budapest, Hungary|47.50|19.04
Warsaw, Poland|52.23|21.01
Krakow, Poland|50.06|19.94
Copenhagen, Denmark|55.68|12.57
Stockholm, Sweden|59.33|18.07
Oslo, Norway|59.91|10.75
Bergen, Norway|60.39|5.32
Helsinki, Finland|60.17|24.94
Reykjavik, Iceland|64.15|-21.94
Athens, Greece|37.98|23.73
Santorini, Greece|36.39|25.46
Heraklion, Crete, Greece|35.34|25.14
Istanbul, Turkey|41.01|28.98
Dubrovnik, Croatia|42.65|18.09
Split, Croatia|43.51|16.44
Moscow, Russia|55.76|37.62
Valletta, Malta|35.90|14.51
Jerusalem, Israel|31.77|35.21
Tel Aviv, Israel|32.09|34.78
Dubai, United Arab Emirates|25.20|55.27
Cairo, Egypt|30.04|31.24
Marrakech, Morocco|31.63|-7.99
Cape Town, South Africa|-33.92|18.42
Johannesburg, South Africa|-26.20|28.05
Nairobi, Kenya|-1.29|36.82
Arusha, Tanzania|-3.37|36.68
Victoria Falls, Zimbabwe|-17.93|25.84
Tokyo, Japan|35.68|139.69
Kyoto, Japan|35.01|135.77
Osaka, Japan|34.69|135.50
Hiroshima, Japan|34.39|132.46
Sapporo, Japan|43.06|141.35
Seoul, South Korea|37.57|126.98
Beijing, China|39.90|116.41
Shanghai, China|31.23|121.47
Hong Kong|22.32|114.17
Xi'an, China|34.34|108.94
Taipei, Taiwan|25.03|121.57
Singapore|1.35|103.82
Bangkok, Thailand|13.76|100.50
Phuket, Thailand|7.88|98.39
Chiang Mai, Thailand|18.79|98.98
Hanoi, Vietnam|21.03|105.85
Ho Chi Minh City, Vietnam|10.82|106.63
Siem Reap (Angkor Wat), Cambodia|13.36|103.86
Kuala Lumpur, Malaysia|3.14|101.69
Bali, Indonesia|-8.41|115.19
Jakarta, Indonesia|-6.21|106.85
Manila, Philippines|14.60|120.98
Delhi, India|28.61|77.21
Agra (Taj Mahal), India|27.18|78.02
Mumbai, India|19.08|72.88
Kathmandu, Nepal|27.72|85.32
Maldives|3.20|73.22
Sydney, Australia|-33.87|151.21
Melbourne, Australia|-37.81|144.96
Brisbane, Australia|-27.47|153.03
Cairns, Australia|-16.92|145.77
Perth, Australia|-31.95|115.86
Auckland, New Zealand|-36.85|174.76
Queenstown, New Zealand|-45.03|168.66
Nadi, Fiji|-17.80|177.42
Tahiti, French Polynesia|-17.65|-149.43
Rio de Janeiro, Brazil|-22.91|-43.17
Sao Paulo, Brazil|-23.55|-46.63
Buenos Aires, Argentina|-34.60|-58.38
Santiago, Chile|-33.45|-70.67
Lima, Peru|-12.05|-77.04
Cusco and Machu Picchu, Peru|-13.52|-71.97
Bogota, Colombia|4.71|-74.07
Cartagena, Colombia|10.39|-75.48
Quito, Ecuador|-0.18|-78.47
Galapagos Islands, Ecuador|-0.74|-90.31
'@
$places = @()
foreach ($line in ($placeText -split "`r?`n")) {
    $p = $line.Trim().Split('|')
    if ($p.Count -eq 3) {
        $places += [pscustomobject]@{
            Name = $p[0]
            Lat  = [double]::Parse($p[1], $inv)
            Lon  = [double]::Parse($p[2], $inv)
        }
    }
}

function Get-DistanceKm([double]$lat1, [double]$lon1, [double]$lat2, [double]$lon2) {
    $r = 6371.0
    $dLat = ($lat2 - $lat1) * [math]::PI / 180
    $dLon = ($lon2 - $lon1) * [math]::PI / 180
    $a = [math]::Sin($dLat / 2) * [math]::Sin($dLat / 2) +
         [math]::Cos($lat1 * [math]::PI / 180) * [math]::Cos($lat2 * [math]::PI / 180) *
         [math]::Sin($dLon / 2) * [math]::Sin($dLon / 2)
    return 2 * $r * [math]::Atan2([math]::Sqrt($a), [math]::Sqrt(1 - $a))
}

$placeCache = @{}
function Get-PlaceName($lat, $lon) {
    if ($null -eq $lat) { return '' }
    $key = ([math]::Round([double]$lat, 2)).ToString($inv) + ',' + ([math]::Round([double]$lon, 2)).ToString($inv)
    if ($placeCache.ContainsKey($key)) { return $placeCache[$key] }
    $best = $null; $bestD = 1e9
    foreach ($p in $places) {
        $d = Get-DistanceKm $lat $lon $p.Lat $p.Lon
        if ($d -lt $bestD) { $bestD = $d; $best = $p }
    }
    if ($bestD -le 40)       { $name = $best.Name }
    elseif ($bestD -le 200)  { $name = 'Near ' + $best.Name }
    else                     { $name = 'A place we could not name' }
    $placeCache[$key] = $name
    return $name
}

# Convert a GPS degrees/minutes/seconds property (3 rationals) to decimal degrees
function Convert-Dms([byte[]]$b) {
    if ($b.Length -lt 24) { return 0.0 }
    $v = @()
    for ($k = 0; $k -lt 3; $k++) {
        $num = [BitConverter]::ToUInt32($b, $k * 8)
        $den = [BitConverter]::ToUInt32($b, $k * 8 + 4)
        if ($den -eq 0) { $v += 0.0 } else { $v += ([double]$num / [double]$den) }
    }
    return ($v[0] + $v[1] / 60 + $v[2] / 3600)
}

# Date taken (EXIF), else earliest of created/modified date; plus GPS if present
function Get-PhotoMeta([string]$path) {
    $fi = Get-Item -LiteralPath $path
    $date = $null; $lat = $null; $lon = $null; $source = 'EXIF'
    if ($exifExt -contains $fi.Extension.ToLower()) {
        $fs = $null; $img = $null
        try {
            $fs  = New-Object IO.FileStream($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
            $img = [Drawing.Image]::FromStream($fs, $false, $false)
            $ids = $img.PropertyIdList
            foreach ($id in 0x9003, 0x9004) {
                if ((-not $date) -and ($ids -contains $id)) {
                    $s = [Text.Encoding]::ASCII.GetString($img.GetPropertyItem($id).Value).TrimEnd([char]0).Trim()
                    $d = [datetime]::MinValue
                    if ([datetime]::TryParseExact($s, 'yyyy:MM:dd HH:mm:ss', $inv, [Globalization.DateTimeStyles]::None, [ref]$d) -and $d.Year -ge 1971) { $date = $d }
                }
            }
            if (($ids -contains 1) -and ($ids -contains 2) -and ($ids -contains 3) -and ($ids -contains 4)) {
                $latRef = [Text.Encoding]::ASCII.GetString($img.GetPropertyItem(1).Value).Substring(0, 1)
                $lonRef = [Text.Encoding]::ASCII.GetString($img.GetPropertyItem(3).Value).Substring(0, 1)
                $latV = Convert-Dms $img.GetPropertyItem(2).Value
                $lonV = Convert-Dms $img.GetPropertyItem(4).Value
                if ($latRef -eq 'S') { $latV = -$latV }
                if ($lonRef -eq 'W') { $lonV = -$lonV }
                if ((($latV -ne 0) -or ($lonV -ne 0)) -and ([math]::Abs($latV) -le 90) -and ([math]::Abs($lonV) -le 180)) {
                    $lat = $latV; $lon = $lonV
                }
            }
        } catch { } finally {
            if ($img) { $img.Dispose() }
            if ($fs)  { $fs.Dispose() }
        }
    }
    if (-not $date) {
        $date = $fi.CreationTime
        if ($fi.LastWriteTime -lt $date) { $date = $fi.LastWriteTime }
        $source = 'file date'
    }
    return [pscustomobject]@{ Date = $date; Lat = $lat; Lon = $lon; Source = $source }
}

# Pick a file name that does not exist yet in a folder (creates the folder if needed)
function New-UniquePath([string]$dir, [string]$fileName) {
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $p = Join-Path $dir $fileName
    $c = 1
    $b = [IO.Path]::GetFileNameWithoutExtension($fileName)
    $e = [IO.Path]::GetExtension($fileName)
    while (Test-Path -LiteralPath $p) {
        $p = Join-Path $dir ('{0} ({1}){2}' -f $b, $c, $e)
        $c++
    }
    return $p
}

# Convert rational numbers returned by Windows imaging (low 32 bits = numerator, high 32 bits = denominator)
function Convert-WicDms($arr) {
    $list = @($arr)
    if ($list.Count -lt 3) { return $null }
    $vals = @()
    for ($k = 0; $k -lt 3; $k++) {
        $r = [uint64]$list[$k]
        $num = [double]($r -band [uint64]4294967295)
        $den = [double]($r -shr 32)
        if ($den -eq 0) { $vals += 0.0 } else { $vals += ($num / $den) }
    }
    return ($vals[0] + $vals[1] / 60 + $vals[2] / 3600)
}

# Read date taken and GPS from a HEIC file through Windows imaging (needs the HEIF extension installed)
function Get-HeicMeta([string]$path) {
    $res = [pscustomobject]@{ Date = $null; Lat = $null; Lon = $null }
    $fs = $null
    try {
        $fs  = [IO.File]::OpenRead($path)
        $dec = [Windows.Media.Imaging.BitmapDecoder]::Create($fs, [Windows.Media.Imaging.BitmapCreateOptions]::DelayCreation, [Windows.Media.Imaging.BitmapCacheOption]::None)
        $md  = $dec.Frames[0].Metadata
        foreach ($pre in '/ifd/exif', '/app1/ifd/exif') {
            foreach ($tag in 36867, 36868) {
                if (-not $res.Date) {
                    $v = $null
                    try { $v = $md.GetQuery(('{0}/{{ushort={1}}}' -f $pre, $tag)) } catch { }
                    if ($v) {
                        $d = [datetime]::MinValue
                        if ([datetime]::TryParseExact(([string]$v).Trim(), 'yyyy:MM:dd HH:mm:ss', $inv, [Globalization.DateTimeStyles]::None, [ref]$d) -and $d.Year -ge 1971) { $res.Date = $d }
                    }
                }
            }
        }
        foreach ($pre in '/ifd/gps', '/app1/ifd/gps') {
            if ($null -eq $res.Lat) {
                $latRef = $null; $lonRef = $null; $latA = $null; $lonA = $null
                try { $latRef = [string]$md.GetQuery(('{0}/{{ushort={1}}}' -f $pre, 1)) } catch { }
                try { $latA   = $md.GetQuery(('{0}/{{ushort={1}}}' -f $pre, 2)) } catch { }
                try { $lonRef = [string]$md.GetQuery(('{0}/{{ushort={1}}}' -f $pre, 3)) } catch { }
                try { $lonA   = $md.GetQuery(('{0}/{{ushort={1}}}' -f $pre, 4)) } catch { }
                if ($latA -and $lonA) {
                    $latV = Convert-WicDms $latA
                    $lonV = Convert-WicDms $lonA
                    if (($null -ne $latV) -and ($null -ne $lonV)) {
                        if ($latRef -like 'S*') { $latV = -$latV }
                        if ($lonRef -like 'W*') { $lonV = -$lonV }
                        if ((($latV -ne 0) -or ($lonV -ne 0)) -and ([math]::Abs($latV) -le 90) -and ([math]::Abs($lonV) -le 180)) {
                            $res.Lat = $latV; $res.Lon = $lonV
                        }
                    }
                }
            }
        }
    } catch { } finally {
        if ($fs) { $fs.Dispose() }
    }
    return $res
}

# Convert a HEIC/HEIF photo to a JPG (keeps the date and GPS information when Windows allows it)
function Convert-HeicToJpg([string]$src, [string]$dst) {
    $in = $null
    try {
        $in  = [IO.File]::OpenRead($src)
        $dec = [Windows.Media.Imaging.BitmapDecoder]::Create($in, [Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat, [Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
        $frame = $dec.Frames[0]
        $saved = $false
        foreach ($withMeta in $true, $false) {
            if ($saved) { break }
            $out = $null
            try {
                $enc = New-Object Windows.Media.Imaging.JpegBitmapEncoder
                $enc.QualityLevel = 92
                if ($withMeta) {
                    $md = $null; $th = $null; $cc = $null
                    try { $md = $frame.Metadata } catch { }
                    try { $th = $frame.Thumbnail } catch { }
                    try { $cc = $frame.ColorContexts } catch { }
                    $f2 = [Windows.Media.Imaging.BitmapFrame]::Create($frame, $th, $md, $cc)
                } else {
                    $f2 = [Windows.Media.Imaging.BitmapFrame]::Create($frame)
                }
                $enc.Frames.Add($f2)
                $out = [IO.File]::Create($dst)
                $enc.Save($out)
                $saved = $true
            } catch {
                if (-not $withMeta) { throw }
            } finally {
                if ($out) { $out.Dispose() }
            }
        }
    } finally {
        if ($in) { $in.Dispose() }
    }
}

# ---- Large-print page for one year (no internet, no outside files) ----
$template = @'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Photos from __YEAR__</title>
<style>
  * { box-sizing: border-box; }
  body { font-family: "Segoe UI", Arial, sans-serif; font-size: 28px; line-height: 1.4; margin: 0; color: #111; background: #fffdf5; }
  header { background: #1b3a5c; color: #fff; padding: 24px 32px; }
  header h1 { margin: 0; font-size: 64px; }
  header a { color: #ffe9a8; font-size: 30px; }
  main { padding: 24px 32px 64px; max-width: 1400px; margin: 0 auto; }
  h2 { font-size: 46px; margin: 8px 0 12px; }
  .summary { background: #fff; border: 4px solid #1b3a5c; border-radius: 16px; padding: 12px 28px 20px; margin-bottom: 40px; }
  .summary ul { list-style: none; margin: 0; padding: 0; }
  .summary li { font-size: 36px; margin: 12px 0; }
  .summary b { color: #1b3a5c; }
  .month { margin-top: 48px; border-top: 6px solid #1b3a5c; padding-top: 12px; }
  .month h2 { font-size: 56px; color: #1b3a5c; }
  .place { margin: 24px 0 8px; font-size: 44px; font-weight: 700; }
  .place.unknown { font-size: 30px; font-weight: 400; color: #444; }
  .count { font-size: 26px; font-weight: 400; color: #444; }
  .grid { display: flex; flex-wrap: wrap; gap: 20px; }
  .tile { display: block; width: 280px; text-decoration: none; color: #111; background: #fff; border: 3px solid #999; border-radius: 12px; overflow: hidden; }
  .tile:hover, .tile:focus { border-color: #1b3a5c; outline: 4px solid #ffbf00; }
  .tile img, .tile .nopic { display: block; width: 100%; height: 210px; object-fit: cover; background: #ddd; }
  .tile .nopic { padding: 70px 10px 0; text-align: center; font-size: 30px; }
  .tile span { display: block; padding: 8px 12px; font-size: 28px; }
  .empty { font-size: 34px; }
</style>
</head>
<body>
<header>
  <h1>Photos from __YEAR__</h1>
  <a href="../Start Here.html">&#8592; Back to all years</a>
</header>
<main>
  <section class="summary" id="summary"></section>
  <div id="months"></div>
</main>
<script>
var DATA = __DATA__;
var MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
var VIDEO = /\.(mp4|mov|avi|mkv|m4v|3gp|wmv)$/i;
var NOSHOW = /\.(heic|heif|dng|cr2|nef|arw|tif|tiff)$/i;
function esc(s) { return String(s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
function url(f) { return f.split('/').map(encodeURIComponent).join('/'); }

var byMonth = {}, monthOrder = [];
DATA.forEach(function (x) {
  if (!byMonth[x.mo]) { byMonth[x.mo] = { places: {}, order: [] }; monthOrder.push(x.mo); }
  var m = byMonth[x.mo], p = x.p || '';
  if (!m.places[p]) { m.places[p] = []; m.order.push(p); }
  m.places[p].push(x);
});
monthOrder.sort(function (a, b) { return a - b; });

var sum = '<h2>Where we went in __YEAR__</h2><ul>';
var anyPlace = false;
monthOrder.forEach(function (mo) {
  var names = byMonth[mo].order.filter(function (p) {
    if (p === '') { return false; }
    if (p.indexOf('Near ') === 0 && byMonth[mo].places[p.substring(5)]) { return false; }
    return true;
  });
  if (names.length) { anyPlace = true; sum += '<li><b>' + MONTHS[mo - 1] + ':</b> ' + names.map(esc).join(' &nbsp;&bull;&nbsp; ') + '</li>'; }
});
if (!anyPlace) { sum += '<li class="empty">These photos do not have a place saved in them.</li>'; }
document.getElementById('summary').innerHTML = sum + '</ul>';

var html = '';
monthOrder.forEach(function (mo) {
  var m = byMonth[mo];
  var order = m.order.filter(function (p) { return p !== ''; });
  if (m.places['']) { order.push(''); }
  html += '<section class="month"><h2>' + MONTHS[mo - 1] + '</h2>';
  order.forEach(function (p) {
    var list = m.places[p];
    html += '<div class="place' + (p === '' ? ' unknown' : '') + '">' + (p === '' ? 'Place not saved in these photos' : esc(p)) +
            ' <span class="count">(' + list.length + (list.length === 1 ? ' photo' : ' photos') + ')</span></div><div class="grid">';
    list.forEach(function (x) {
      var day = parseInt(x.d.substring(8, 10), 10);
      var pic = VIDEO.test(x.f) ? '<div class="nopic">Video</div>' : NOSHOW.test(x.f) ? '<div class="nopic">Photo (click to open)</div>' : '<img loading="lazy" src="' + esc(url(x.f)) + '" alt="" onerror="this.outerHTML=\'<div class=nopic>Photo</div>\'">';
      html += '<a class="tile" href="' + esc(url(x.f)) + '">' + pic + '<span>' + MONTHS[mo - 1] + ' ' + day + '</span></a>';
    });
    html += '</div>';
  });
  html += '</section>';
});
document.getElementById('months').innerHTML = html;
</script>
</body>
</html>
'@

$indexTemplate = @'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Our Photos</title>
<style>
  * { box-sizing: border-box; }
  body { font-family: "Segoe UI", Arial, sans-serif; font-size: 32px; margin: 0; background: #fffdf5; color: #111; }
  header { background: #1b3a5c; color: #fff; padding: 28px 40px; }
  h1 { margin: 0; font-size: 70px; }
  main { padding: 32px 40px 64px; max-width: 1300px; margin: 0 auto; }
  p.lead { font-size: 34px; margin: 0 0 16px; }
  .years { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 16px; }
  a.year { display: block; padding: 12px 16px; font-size: 28px; font-weight: 700; text-align: center; color: #fff; background: #1b3a5c; border-radius: 12px; text-decoration: none; }
  a.year:hover, a.year:focus { background: #0f2540; outline: 5px solid #ffbf00; }
  a.year small { display: block; font-size: 18px; font-weight: 400; }
  #random { margin-top: 48px; border-top: 6px solid #1b3a5c; padding-top: 16px; }
  #random h2 { font-size: 48px; color: #1b3a5c; margin: 0 0 16px; }
  #random img { display: block; max-width: 100%; max-height: 70vh; border: 4px solid #1b3a5c; border-radius: 12px; background: #ddd; }
  #rcap { font-size: 38px; font-weight: 700; margin: 16px 0; }
  #rbtn { font-family: inherit; font-size: 32px; padding: 14px 28px; color: #fff; background: #1b3a5c; border: 0; border-radius: 12px; cursor: pointer; }
  .backup { font-size: 30px; margin-top: 40px; }
  .backup a { color: #1b3a5c; }
  #rbtn:hover, #rbtn:focus { background: #0f2540; outline: 5px solid #ffbf00; }
</style>
</head>
<body>
<header><h1>Our Photos</h1></header>
<main>
<p class="lead">Click a year to see where we went.</p>
<div class="years">
__LINKS__
</div>
<section id="random" hidden>
  <h2 id="rtitle"></h2>
  <a id="rlink" href="#"><img id="rimg" alt="A random photo"></a>
  <div id="rcap"></div>
  <button id="rbtn" type="button">Show another photo</button>
</section>
<p class="backup">__BACKUP__</p>
</main>
<script>
var PHOTOS = __DATA__;
var MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
var cm = new Date().getMonth() + 1;
var pool = PHOTOS.filter(function (x) { return x.mo === cm; });
var thisMonth = pool.length > 0;
if (!thisMonth) { pool = PHOTOS; }
function url(f) { return f.split('/').map(encodeURIComponent).join('/'); }
var last = -1, tries = 0;
function show() {
  if (!pool.length) { return; }
  var i = Math.floor(Math.random() * pool.length);
  if (pool.length > 1 && i === last) { i = (i + 1) % pool.length; }
  last = i;
  var x = pool[i];
  document.getElementById('rtitle').textContent = thisMonth ? 'A memory from ' + MONTHS[cm - 1] : 'A memory from our photos';
  document.getElementById('rimg').src = url(x.f);
  document.getElementById('rlink').href = url(x.f);
  document.getElementById('rcap').textContent = MONTHS[x.mo - 1] + ' ' + x.y + (x.p ? ' - ' + x.p : '');
  document.getElementById('random').hidden = false;
}
document.getElementById('rimg').onerror = function () { if (tries < 8) { tries++; show(); } };
document.getElementById('rimg').onload = function () { tries = 0; };
document.getElementById('rbtn').onclick = show;
show();
</script>
</body>
</html>
'@

Write-Host ''
Write-Host "Folder: $root"
Write-Host 'Scanning for photos and videos...'
$files = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $rel = $_.FullName.Substring($root.Length + 1)
    $ext = $_.Extension.ToLower()
    ($mediaExt -contains $ext) -and
    ($rel -notlike ($backupName + '\*')) -and
    (($rel -notmatch '^\d{4}\\\d{2}-[A-Za-z]+\\') -or ($ConvertOldHeic -and ($heicExt -contains $ext)))
})
Write-Host ('Found {0} file(s) to organize.' -f $files.Count)

$cache = @{}
$log = New-Object System.Collections.ArrayList
$moved = 0; $failed = 0; $fromExif = 0; $fromFile = 0
$converted = 0; $convFail = 0; $codecMissing = $false

if ($files.Count -gt 0) {
    $ans = Read-Host 'Move them into Year\Month folders (iPhone HEIC photos will be converted to JPG)? (Y/N)'
    if ($ans -notmatch '^[Yy]') { Write-Host 'Cancelled. Nothing was changed.'; return }

    $n = 0
    foreach ($f in $files) {
        $n++
        if ($n % 25 -eq 0) { Write-Host ('  {0} / {1}' -f $n, $files.Count) }
        try {
            $ext = $f.Extension.ToLower()

            # --- iPhone HEIC photos: convert to JPG, keep the original in the backup folder ---
            if ((-not $codecMissing) -and ($heicExt -contains $ext)) {
                $tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString('N') + '.jpg')
                $ok = $false
                try {
                    Convert-HeicToJpg $f.FullName $tmp
                    $ok = (Test-Path -LiteralPath $tmp) -and ((Get-Item -LiteralPath $tmp).Length -gt 0)
                } catch { $ok = $false }
                if ($ok) {
                    $m = Get-PhotoMeta $tmp
                    if (($m.Source -ne 'EXIF') -or ($null -eq $m.Lat)) {
                        $h = Get-HeicMeta $f.FullName
                        $newDate = $m.Date; $newSrc = $m.Source; $newLat = $m.Lat; $newLon = $m.Lon
                        if ($m.Source -ne 'EXIF') {
                            if ($h.Date) { $newDate = $h.Date; $newSrc = 'EXIF' }
                            else { $o = Get-PhotoMeta $f.FullName; $newDate = $o.Date; $newSrc = 'file date' }
                        }
                        if (($null -eq $newLat) -and ($null -ne $h.Lat)) { $newLat = $h.Lat; $newLon = $h.Lon }
                        $m = [pscustomobject]@{ Date = $newDate; Lat = $newLat; Lon = $newLon; Source = $newSrc }
                    }
                    $sub = $m.Date.ToString('yyyy', $inv) + '\' + $m.Date.ToString('MM-MMMM', $inv)
                    $destJpg = New-UniquePath (Join-Path $root $sub) ([IO.Path]::GetFileNameWithoutExtension($f.Name) + '.jpg')
                    [IO.File]::Move($tmp, $destJpg)
                    try { (Get-Item -LiteralPath $destJpg).LastWriteTime = $m.Date } catch { }
                    $backupDest = New-UniquePath (Join-Path (Join-Path $root $backupName) $sub) $f.Name
                    [IO.File]::Move($f.FullName, $backupDest)
                    [void]$log.Add([pscustomobject]@{ From = $f.FullName; To = $destJpg; Backup = $backupDest })
                    $cache[$destJpg] = $m
                    $moved++; $converted++
                    if ($m.Source -eq 'EXIF') { $fromExif++ } else { $fromFile++ }
                    continue
                }
                if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
                $convFail++
                if (($convFail -ge 3) -and ($converted -eq 0)) { $codecMissing = $true }
            }

            # --- everything else (or HEIC that could not be converted): move into Year\Month ---
            $m = Get-PhotoMeta $f.FullName
            $sub = $m.Date.ToString('yyyy', $inv) + '\' + $m.Date.ToString('MM-MMMM', $inv)
            $destDir = Join-Path $root $sub
            if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
            $dest = Join-Path $destDir $f.Name
            if ($dest -ne $f.FullName) {
                $backupCopy = ''
                if ($BackupEveryOriginal) {
                    $backupCopy = New-UniquePath (Join-Path (Join-Path $root $backupName) $sub) $f.Name
                    [IO.File]::Copy($f.FullName, $backupCopy)
                }
                $dest = New-UniquePath $destDir $f.Name
                [IO.File]::Move($f.FullName, $dest)
                [void]$log.Add([pscustomobject]@{ From = $f.FullName; To = $dest; Backup = $backupCopy })
                $cache[$dest] = $m
                $moved++
                if ($m.Source -eq 'EXIF') { $fromExif++ } else { $fromFile++ }
            }
        } catch {
            $failed++
            Write-Host ('  Could not move {0}: {1}' -f $f.Name, $_.Exception.Message)
        }
    }

    if ($log.Count -gt 0) {
        $logPath = Join-Path $root ('organize-log-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.csv')
        $log | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8
        Write-Host "Move log saved: $logPath"
    }

    # Remove folders left empty by the moves (deepest first). Folders starting with a dot (like .git) are never touched.
    $removed = 0
    $dirs = @(Get-ChildItem -LiteralPath $root -Directory -Recurse -Force |
        Where-Object { $_.FullName.Substring($root.Length) -notmatch '\\\.' } |
        Sort-Object { $_.FullName.Length } -Descending)
    foreach ($d in $dirs) {
        if (-not (Test-Path -LiteralPath $d.FullName)) { continue }
        $kids = @(Get-ChildItem -LiteralPath $d.FullName -Force)
        $junk = @($kids | Where-Object { (-not $_.PSIsContainer) -and (@('Thumbs.db', 'desktop.ini') -contains $_.Name) })
        if ($kids.Count -eq $junk.Count) {
            try { Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop; $removed++ } catch { }
        }
    }
    Write-Host ('Removed {0} empty folder(s).' -f $removed)
}

# Build the large-print page for every Year folder (includes photos organized in earlier runs)
Write-Host 'Building large-print pages...'
$utf8 = New-Object Text.UTF8Encoding($false)
$yearDirs = @(Get-ChildItem -LiteralPath $root -Directory | Where-Object { $_.Name -match '^\d{4}$' } | Sort-Object Name)
$links = ''
$webExt = '.jpg','.jpeg','.png','.gif','.bmp','.webp'
$indexItems = New-Object System.Collections.ArrayList
foreach ($yd in $yearDirs) {
    $items = New-Object System.Collections.ArrayList
    $monthDirs = @(Get-ChildItem -LiteralPath $yd.FullName -Directory | Where-Object { $_.Name -match '^\d{2}-[A-Za-z]+$' })
    foreach ($md in $monthDirs) {
        $mediaHere = @(Get-ChildItem -LiteralPath $md.FullName -File | Where-Object { $mediaExt -contains $_.Extension.ToLower() })
        foreach ($file in $mediaHere) {
            $m = $cache[$file.FullName]
            if (-not $m) { $m = Get-PhotoMeta $file.FullName }
            [void]$items.Add([pscustomobject]@{
                f  = ($md.Name + '/' + $file.Name)
                d  = $m.Date.ToString('yyyy-MM-dd', $inv)
                mo = [int]$m.Date.Month
                p  = (Get-PlaceName $m.Lat $m.Lon)
            })
        }
    }
    if ($items.Count -eq 0) { continue }
    foreach ($it in $items) {
        if ($webExt -contains ([IO.Path]::GetExtension($it.f).ToLower())) {
            [void]$indexItems.Add([pscustomobject]@{ f = ($yd.Name + '/' + $it.f); y = $yd.Name; mo = $it.mo; p = $it.p })
        }
    }
    $sorted = @($items | Sort-Object d, f)
    $json = (ConvertTo-Json -InputObject $sorted -Compress) -replace '</', '<\/'
    $html = $template.Replace('__YEAR__', $yd.Name).Replace('__DATA__', $json)
    $htmlPath = Join-Path $yd.FullName ('Photos-' + $yd.Name + '.html')
    [IO.File]::WriteAllText($htmlPath, $html, $utf8)
    $links += ('<a class="year" href="{0}/Photos-{0}.html">{0}<small>{1} photos</small></a>' -f $yd.Name, $items.Count) + "`r`n"
    Write-Host ('  {0}: {1} files' -f $yd.Name, $items.Count)
}
if ($links) {
    $indexJson = (ConvertTo-Json -InputObject @($indexItems) -Compress) -replace '</', '<\/'
    $backupLink = ''
    if (Test-Path -LiteralPath (Join-Path $root $backupName)) {
        $backupLink = '<a href="' + [uri]::EscapeDataString($backupName) + '/">Look at the original photos (backup)</a>'
    }
    $indexHtml = $indexTemplate.Replace('__LINKS__', $links).Replace('__DATA__', $indexJson).Replace('__BACKUP__', $backupLink)
    [IO.File]::WriteAllText((Join-Path $root 'Start Here.html'), $indexHtml, $utf8)
    Write-Host 'Made "Start Here.html" in the main folder.'
}

Write-Host ''
Write-Host ('Done. Moved {0} file(s) ({1} by date taken, {2} by created date). Failed: {3}.' -f $moved, $fromExif, $fromFile, $failed)
if ($converted -gt 0) {
    Write-Host ('Converted {0} iPhone (HEIC) photo(s) to JPG. The originals are in the "{1}" folder.' -f $converted, $backupName)
}
if ($convFail -gt 0) {
    Write-Host ''
    Write-Host ('{0} iPhone (HEIC) photo(s) could not be converted and were left as they are.' -f $convFail)
    Write-Host 'Windows needs two free add-ons from the Microsoft Store to read them:'
    Write-Host '   "HEIF Image Extensions" and "HEVC Video Extensions"'
    Write-Host 'Install them on a computer with internet, then run this file again to convert them.'
}
