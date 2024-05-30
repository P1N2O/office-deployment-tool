# Office Deployment Tool v16.0.17531.20046

The Office Deployment Tool (ODT) is a command-line tool that you can use to download and deploy Click-to-Run versions of Office, such as Microsoft 365 Apps for enterprise, to your client computers.

## Download

```cmd
setup.exe /download ProPlus2021Volume.xml
```

## Installation

```cmd
setup.exe /configure ProPlus2021Volume.xml
```

## Pack (App-V Package)

```cmd
setup.exe /packager ProPlus2021Volume.xml
```

## Customize

```cmd
setup.exe /customize ProPlus2021Volume.xml
```

## Convert (Retail to Volume)

```cmd
cd /d %ProgramFiles%\Microsoft Office\Office16
```

```cmd
for /f %x in ('dir /b ..\root\Licenses16\ProPlus2019VL*.xrm-ms') do cscript ospp.vbs /inslic:"..\root\Licenses16\%x"
```

## Activate

```cmd
cd /d %ProgramFiles%\Microsoft Office\Office16
```

```cmd
cscript ospp.vbs /sethst:<KMS_HOST_ADDRESS>
```

```cmd
cscript ospp.vbs /act
```

Official Links: [Microsoft Download Center - ODT](https://www.microsoft.com/en-us/download/details.aspx?id=49117) | [Microsoft Docs - ODT Overview](https://docs.microsoft.com/en-us/deployoffice/overview-office-deployment-tool)
