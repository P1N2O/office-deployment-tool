# Office Deployment Tool

The Office Deployment Tool (ODT) is a command-line tool that you can use to download and deploy Click-to-Run versions of Office, such as Microsoft 365 Apps for enterprise, to your client computers.

## Installation (Automated)

```powershell
powershell -c "irm https://raw.githubusercontent.com/P1N2O/office-deployment-tool/main/install.ps1 | iex"
```

## ODT Commands

### Installation

```cmd
setup.exe /configure office365.xml
```

### Customize

```cmd
setup.exe /customize office365.xml
```

### Download

```cmd
setup.exe /download office365.xml
```

### Pack (App-V Package)

```cmd
setup.exe /packager office365.xml
```

Official Links: [Microsoft Download Center - ODT](https://www.microsoft.com/en-us/download/details.aspx?id=49117) | [Microsoft Docs - ODT Overview](https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/overview-office-deployment-tool)
