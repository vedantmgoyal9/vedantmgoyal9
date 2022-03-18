/* eslint-disable camelcase */
const core = require('@actions/core')
const github = require('@actions/github')
const exec = require('@actions/exec')
const https = require('https')
const crypto = require('crypto')
const path = require('path')
const { Octokit } = require('octokit')
const yaml = require('js-yaml')
const fs = require('fs')

const usr = github.context.repo.owner
const repo = github.context.repo.repo
const pkgid = core.getInput('id')
const tag = core.getInput('tag_name')
const ver_method = core.getInput('version_method')
const ver_regex = new RegExp(core.getInput('version_regex'), 'g')
const inst_regex = new RegExp(core.getInput('installer_regex'), 'g')
const pat = core.getInput('token')

core.info('Checking whether the operating system is Windows or not...')
if (process.platform !== 'win32') {
  core.error('This action is only supported on Windows')
  process.exit(1)
}

core.info('Checking whether event type is release or not...')
if (github.context.eventName !== 'release') {
  core.error('This action is only supported on release event')
  process.exit(1)
}

core.info('Checking whether the user has forked winget-pkgs repository or not...')
https.get('https://github.com/' + usr + '/winget-pkgs', (res) => {
  if (res.statusCode !== 200) {
    core.error('You have not forked winget-pkgs repository')
    process.exit(1)
  }
})

core.info('Checking whether the package already exists in winget-pkgs repository or not...')
https.get('https://github.com/microsoft/winget-pkgs/tree/master/manifests/' + pkgid.charAt(0).toLowerCase() + '/' + pkgid.replace('.', '/'), (res) => {
  if (res.statusCode !== 200) {
    core.error('Package does not exist in winget-pkgs repository')
    process.exit(1)
  }
})

core.info('\nChecks passed, continuing...')

core.info('Installing winget-cli...')
exec.exec('Invoke-WebRequest', ['-Uri', 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx', '-OutFile', 'VCLibs.appx'])
exec.exec('Invoke-WebRequest', ['-Uri', 'https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle', '-OutFile', 'winget.msixbundle'])
exec.exec('Invoke-WebRequest', ['-Uri', 'https://github.com/microsoft/winget-cli/releases/download/v1.1.12701/9c0fe2ce7f8e410eb4a8f417de74517e_License1.xml', '-OutFile', 'license.xml'])
exec.exec('Import-Module', ['-Name', 'Appx', '-UseWindowsPowerShell'])
exec.exec('Add-AppxProvisionedPackage', ['-Online', '-PackagePath', '.\\winget.msixbundle', 'DependencyPackagePath', '.\\VCLibs.appx', '-LicensePath', '.\\license.xml'])
exec.exec('Install-Module', ['NtObjectManager', '-Force'])
exec.exec('Set-ExecutionAlias', ['-Path', 'C:\\Windows\\System32\\winget.exe', '-PackageName', 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe', '-EntryPoint', 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget', '-Target', '$((Get-AppxPackage Microsoft.DesktopAppInstaller).InstallLocation)\\AppInstallerCLI.exe', '-AppType', 'Desktop', '-Version', '3'])
exec.exec('explorer.exe', ['"shell:appsFolder\\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe!winget"'])
exec.exec('winget', ['settings', '--enable', 'LocalManifestFiles'])
core.info('Successfully installed winget-cli, continuing...')

core.info('\nGetting urls and sha256 hashes of the installers...')
let downurl = null
let downhash = null
let downfile = null
let release_notes_url = null
let inst_data = new Map()
const octokit = new Octokit({
  auth: pat
})
async function apiRequest () {
  return await octokit.request('GET /repos/{owner}/{repo}/releases/{release_id}', {
    owner: usr,
    repo: repo,
    release_id: github.context.payload.release.id
  })
}
apiRequest().then((res) => {
  release_notes_url = res.data.html_url
  res.data.assets.forEach((asset) => {
    if (asset.name.match(inst_regex)) {
      downurl = asset.browser_download_url
      https.get(downurl, (res) => {
        downfile = fs.createWriteStream(path.join(__dirname, asset.name))
        res.pipe(downfile)
        downfile.on('finish', () => {
          downfile.close()
          downhash = 'fmwl' // crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname, asset.name))).digest('hex')
        })
      })
      inst_data.set(downurl, downhash)
    }
  })
})
inst_data = new Map([...inst_data.entries()].sort())
for (const [uri, sha_hash] of inst_data) {
  console.log('-> Url: ' + uri + '\n   SHA-256: ' + sha_hash)
}

core.info('\nGetting version of the package using method: ' + ver_method)
let pkgver = null
if (ver_method === 'trim-tag') {
  pkgver = tag.replace(ver_regex, '')
} else if (ver_method === 'get-from-url') {
  pkgver = inst_data.keys().next().value.match(ver_regex)[0]
} else {
  core.error('Invalid version_method specified')
  process.exit(1)
}

core.info('\nUpdating manifests...')

const options = {}
options.listeners = {
  stdout: (stdoutput) => {
    console.log(stdoutput.toString())
  },
  stderr: (stderorr) => {
    console.log(stderorr.toString())
  }
}

async function cloneRepo () {
  await exec.exec('git', ['clone', 'https://' + usr + ':' + pat + '@github.com/microsoft/winget-pkgs.git', '--quiet'], options)
  await exec.exec('git', ['remote', 'rename', 'origin', 'upstream'], { cwd: 'winget-pkgs', options })
  await exec.exec('git', ['remote', 'add', 'origin', 'https://github.com/' + usr + '/winget-pkgs.git'], { cwd: 'winget-pkgs', options })
  return null
}
cloneRepo()
const pkg_dir = path.join('winget-pkgs', 'manifests', pkgid.charAt(0).toLowerCase(), pkgid.replace('.', '/'))

path.join(pkg_dir, (fs.readdirSync(pkg_dir).forEach((item) => {
  return fs.statSync(path.join(pkg_dir, item)).isDirectory()
})).slice(-1)[0]).then((lastver) => {
  fs.readdirSync(lastver).forEach((file) => {
    if (/\.installer\.yaml$/g.test(file)) {
      const inst_manifest = yaml.safeLoad(fs.readFileSync(file, 'utf8'))
      inst_manifest.PackageVersion = pkgver
      inst_manifest.Installers.sort((a, b) => {
        return a.InstallerUrl < b.InstallerUrl ? -1 : a.InstallerUrl > b.InstallerUrl ? 1 : 0
      })
      inst_manifest.Installers.forEach((inst) => {
        inst.InstallerUrl = inst_data.get(inst.InstallerUrl)
        inst.InstallerSha256 = inst_data.get(inst.InstallerSha256)
        // if (/{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}/g.test(inst.ProductCode)) {
        //   inst.ProductCode = getProductCode(inst.InstallerUrl)
        // }
        // if (/\.(msix|appx)(bundle){0,1}$/g.test(inst.InstallerUrl)) {
        //   inst.InstallerSha256 = getSignatureSha256(inst.InstallerUrl)
        // }
      })
      fs.writeFileSync(path.join(pkg_dir, pkgver, path.basename(file)), yaml.safeDump(inst_manifest, { lineWidth: -1 }), 'utf8')
    } else if (/\.locale\./g.test(file)) {
      const locale_manifest = yaml.safeLoad(fs.readFileSync(file, 'utf8'))
      locale_manifest.PackageVersion = pkgver
      locale_manifest.ReleaseNotesUrl = release_notes_url
      fs.writeFileSync(path.join(pkg_dir, pkgver, path.basename(file)), yaml.safeDump(locale_manifest, { lineWidth: -1 }), 'utf8')
    } else {
      const version_manifest = yaml.safeLoad(fs.readFileSync(file, 'utf8'))
      version_manifest.PackageVersion = pkgver
      fs.writeFileSync(path.join(pkg_dir, pkgver, path.basename(file)), yaml.safeDump(version_manifest, { lineWidth: -1 }), 'utf8')
    }
  })
})

core.info('Pushing branch to fork and creating pull request...')
const branchname = 'winget-releaser/' + pkgid + '-' + pkgver
async function submitPR () {
  await exec.exec('git', ['checkout', '-b', branchname], { cwd: 'winget-pkgs', options })
  await exec.exec('git', ['add', '-A'], { cwd: 'winget-pkgs', options })
  await exec.exec('git', ['commit', '-m', 'New Version: ' + pkgid + 'version ' + pkgver], { cwd: 'winget-pkgs', options })
  await exec.exec('git', ['push', '-u', 'origin', branchname], { cwd: 'winget-pkgs', options })
  await octokit.request('POST /repos/{owner}/{repo}/pulls', {
    owner: 'microsoft',
    repo: 'winget-pkgs',
    title: 'Update ' + pkgid + ' to ' + pkgver,
    body: 'This is an automated pull request generated by winget-releaser.',
    head: branchname,
    base: 'master'
  })
  return null
}
submitPR()
