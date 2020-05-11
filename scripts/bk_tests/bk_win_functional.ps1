echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

echo "--- configure winrm"

winrm quickconfig -q

echo "--- installing ruby"

choco install ruby -y
refreshenv
ruby -v
if (-not $?) { throw "Unable to install ruby" }

echo "--- remove chocolatey to avoid those tests running :("

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

echo "--- configure winrm"

winrm quickconfig -q

echo "--- update bundler and rubygems"

ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

$env:RUBYGEMS_VERSION=$(findstr rubygems omnibus_overrides.rb | %{ $_.split(" ")[3] })
$env:BUNDLER_VERSION=$(findstr bundler omnibus_overrides.rb | %{ $_.split(" ")[3] })

$env:RUBYGEMS_VERSION=($env:RUBYGEMS_VERSION -replace '"', "")
$env:BUNDLER_VERSION=($env:BUNDLER_VERSION -replace '"', "")

echo $env:RUBYGEMS_VERSION
echo $env:BUNDLER_VERSION

gem update --system $env:RUBYGEMS_VERSION
if (-not $?) { throw "Unable to update system Rubygems" }
gem --version
gem install bundler -v $env:BUNDLER_VERSION --force --no-document --quiet
if (-not $?) { throw "Unable to update Bundler" }
bundle --versio

echo "--- bundle install"
bundle install --jobs=3 --retry=3 --without omnibus_package docgen chefstyle
if (-not $?) { throw "Unable to install gem dependencies" }

echo "+++ bundle exec rake spec:functional"
bundle exec rake spec:functional
if (-not $?) { throw "Chef functional specs failing." }
