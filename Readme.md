###  Allow any app (including Docker) to run under ANCM with access the IIS user identity

ANCM is architected as a generic reverse proxy, but a couple of implementation choices
currently limit its usefulness to only ASP.NET Core apps.

The repository [`nil4/IISIntegration`](https://github.com/nil4/IISIntegration) contains
an ANCM fork that adds a few ***opt-in*** settings to enable any other application to run with ANCM,
and be provided access to the IIS authenticated user identity.
The [`ancmv2_extra/Readme.md` file](https://github.com/nil4/ANCM-AnyApp/blob/master/ancmv2_extra/Readme.md) describes:
- the handshake protocol between ANCM and its backend app
- the protocol used to [securely pass requests to the backend app](https://github.com/nil4/IISIntegration#security)
- the implications of the ANCM design choice to pass the IIS user identity (a Windows token/handle) to the backend app,
which currently restricts its relevance to only ASP.NET Core apps

It also describes a few extra features added by the ANCM fork.

This repository contains demo apps that use these extra ANCM features to show how
*any other application type* (*in addition to* ASP.NET Core) could be hosted on IIS/Windows.

> :warning: The **forked** ANCM binaries are stored in this repo,
under [/ancmv2_extra](https://github.com/nil4/ANCM-AnyApp/tree/master/ancmv2_extra),
and are used to run these demo apps.

## Prerequisites and one-time setup

[IIS Express 10](https://www.microsoft.com/en-us/download/details.aspx?id=48264)
and the .NET Core 2.1 [Runtime & Hosting Bundle](https://www.microsoft.com/net/download/dotnet-core/2.1)
(which installs ANCM) are required to run these demos.

In addition, a one-time setup step needs to be performed. The demos use ANCM version 2
(which is *not* installed by the .NET Core 2.1 bundle), and the extra features implemented
by the ANCM fork require an additional IIS Express schema file.

If the schema files are not installed, IIS Express will not recognize the extra attributes
of the `<aspNetCore>` element in `Web.config` and will fail to start the demo apps.

To install the two schemas, copy these files to `%ProgramFiles%\IIS Express\config\schema`:
- [ancmv2_extra/aspnetcore_schema_v2.xml](https://github.com/nil4/ANCM-AnyApp/blob/master/ancmv2_extra/aspnetcore_schema_v2.xml)
- [ancmv2_extra/aspnetcore_schema_v2_extra.xml](https://github.com/nil4/ANCM-AnyApp/blob/master/ancmv2_extra/aspnetcore_schema_v2_extra.xml)

The batch files that launch the demo apps will test the prerequisites, and remind you to install/copy them if needed.

### NodeJS demo

If you have [NodeJS](https://nodejs.org/en/) installed, start
[`run-node.cmd`](https://github.com/nil4/ANCM-AnyApp/blob/master/run-node.cmd) in a command prompt.

This starts IIS Express, listening on `http://localhost:50690`, writing detailed logs to the console window,
and ANCM will launch [`node/server.js`](https://github.com/nil4/ANCM-AnyApp/blob/master/node/server.js) as the backend
application. Like all other demos, the batch file will also open `http://localhost:50690` in your browser.

Things to note:

- A greeting similar to: `Hello from NodeJS, YourDomain\UserName!` should be displayed

  IIS Express is configured to use Windows authentication, and the `forwardUserName="true"` setting
  in [node/Web.config](https://github.com/nil4/ANCM-AnyApp/blob/master/node/Web.config) requests ANCM to
  pass the IIS authenticated user name to the NodeJS application as a request header.

- Below the greeting, all request headers forwarded by ANCM are displayed, and among them you will find `ms-aspnetcore-user`.

  This is the header that the ANCM fork uses, by default, to pass the *name* of the authenticated IIS user,
  which makes it useful regardless of the backend app technology.

  In contrast, the *handle/token* passed by ANCM by default (e.g. to an ASP.NET Core app)  *requires* the app
  to call Win32 APIs to *convert* the handle into a user identity, and then close the handle at the end
  of the request to avoid resource leaks. This is disabled explicitly here by `forwardWindowsAuthToken="false"`.

- Edit `node/Web.config` and set `forwardUserDomain="false"`, then refresh the browser page.

  You should see the greeting update to just `Hello from NodeJS, UserName!`.

  Note that whenever you change Web.config, ANCM stops the NodeJS application, and starts it again
  on the next request. You can see the relevant ANCM process management messages in the console window.

- Edit `node/Web.config` and set `forwardUserName="false"`, then refresh the browser page.

  The user name header (`ms-aspnetcore-user`) is no longer passed to the back-end app,
  and the greeting is no longer shown.

- Edit `node/Web.config`, set `forwardUserName="true"`, and then disable Windows authentication
  (`<windowsAuthentication enabled="false" />`) and enable anonymous instead (`<anonymousAuthentication enabled="true">`).

  The greeting is not shown (as the anonymous user name is empty), but note that the `ms-aspnetcore-user` *is still passed*.
  Regardless of the active IIS authentication method, the header is always send when `forwardUserName` is set
  to `true`, such that the backend app can reliably use it for authorization purposes.

  In contrast to the out-of-the-box ANCM functionality, which only forwards a *Windows authentication* tokens
  to ASP.NET Core apps, the `forwardUserName` setting works with [all authentication methods
  supported by IIS](https://msdn.microsoft.com/en-us/library/ms689371(v=vs.90).aspx).

- The `node/server.js` script implements the same request security protocol that ASP.NET Core applications implement.

  To test this, search the IIS Express console log for a line similar to:

  > Application '/LM/W3SVC/1/ROOT' started process '1234' successfully and process '1234' is listening on port '**44836**'.

  Here, the NodeJS application is running on port 44836; open `http://localhost:44836` in your browser.

  Because direct requests do not include the correct `ms-aspnetcore-token` token, you will see an error message:
  `Invalid request: ANCM token mismatch`.

Press <kbd>Q</kbd> in the console window to stop IIS Express before trying the next demo.

### Python demo

If you have [Python 3](https://www.python.org/) installed, start
[`run-python.cmd`](https://github.com/nil4/ANCM-AnyApp/blob/master/run-python.cmd) in a command prompt.

Similar to the previous demo, this will launch [python/server.py](https://github.com/nil4/ANCM-AnyApp/blob/master/python/server.py)
under ANCM/IIS Express, and open `http://localhost:50690` in your browser.

The Python demo has the same functionality as the NodeJS demo (including the ANCM security handshake protocol).
All the experiments in the NodeJS demo are applicable here as well.

### Docker demo

If you have [Docker for Windows](https://store.docker.com/editions/community/docker-ce-desktop-windows) installed,
with experimental features enabled, i.e. LCOW ([Linux Containers on Windows](https://github.com/linuxkit/lcow)) available,
start [`run-docker.cmd`](https://github.com/nil4/ANCM-AnyApp/blob/master/run-docker.cmd) in a command prompt.

This will pull the [paddycarey/go-echo](https://hub.docker.com/r/paddycarey/go-echo/) image (a very simple
HTTP server, written in Go and running on Alpine Linux, that echoes request headers as a JSON-formatted response).

It will then *hopefully* run the image under ANCM and IIS Express; the Docker LCOW support is still experimental,
after all; if all else fail, restart Docker for Windows, and set `stdoutLogEnabled="true"` in `docker/Web.config`,
which should create log files with hints about any issue.

If it works, you should see a JSON response in your browser, with the ANCM-forwarded request headers,
including `ms-aspnetcore-token` and  `ms-aspnetcore-user`.

Things to note:

- Currently, ANCM does not replace `%ASPNETCORE_PORT%` in the command line of the process it starts.
  But Docker expects the port mapping (`-pHostPort:ContainerPort`) to be passed through the command line.

  Fortunately, ANCM allows specifying the port to use (as opposed to generating a random port every time)
  through an environment variable.

  Therefore, in this demo, the backend app port is be hardcoded in both
  [`run-docker.cmd`](https://github.com/nil4/ANCM-AnyApp/blob/4c786184be6b90b782866c4c7844eb65c1ac80ad/run-docker.cmd#L5)
  and [`docker/Web.config`](https://github.com/nil4/ANCM-AnyApp/blob/4c786184be6b90b782866c4c7844eb65c1ac80ad/docker/Web.config#L19).

- Note the `disableProcessIdCheck="true"` setting in [`docker/Web.config`](https://github.com/nil4/ANCM-AnyApp/blob/4c786184be6b90b782866c4c7844eb65c1ac80ad/docker/Web.config#L17)

  This is a setting added by the ANCM fork, and is required here because ANCM version 2 expects the process *it* launched
  (or one of its child processes) to be listening on the configured port. However, while the user program `docker.exe`
  *triggers* a container to start, the running container is *actually hosted* by a system service
  (`com.docker.service`&mdash;the Docker daemon), and it is *this service* that actually opens the port that ANCM needs to proxy to.

  When the `disableProcessIdCheck` is set to `false` (the default value), ANCM will successfully launch `docker.exe`,
  but then will time out trying to find the listening port (`18000`) attached to the `docker.exe` process, and
  because there is no such port, it will eventually give up and consider the process launch failed.

  Setting `disableProcessIdCheck="true"` turns off this check, allowing ANCM to proxy to an existing port,
  regardless of which process opens it.

- The `run-docker.cmd` file [explicitly stops](https://github.com/nil4/ANCM-AnyApp/blob/master/run-docker.cmd#L15-L16)
  the Docker container when IIS Express exits, to release the port it listens on.

### ASP.NET Core demo

If you have [.NET Core SDK 2.1](https://www.microsoft.com/net/download/dotnet-core/2.1) installed,
start `run-dotnet.cmd` in a command prompt.

This will build [`dotnet/TestANCM.csproj`](https://github.com/nil4/ANCM-AnyApp/blob/master/dotnet/TestANCM.csproj)
and run the `netcoreapp2.1` application under the ANCM fork.
Just like the regular ANCM, Windows authentication *tokens* are passed to the application; in your browser, you should see:

```
HttpContext.User.Identity.Name = YourDomain\UserName
Header[MS-ASPNETCORE-USER]     =
ASPNETCORE_IIS_HTTPAUTH        = windows;
```

Try the following:
- set `forwardWindowAuthToken="false"` in [`dotnet/Web.config`](https://github.com/nil4/ANCM-AnyApp/blob/master/dotnet/Web.config);
  note that `HttpContext.User.Identity.Name` is now empty.

- set `forwardUserName="true"`; note that `Header[MS-ASPNETCORE-USER]` is now set to `YourDomain\UserName`.

### ASP.NET Core on Alpine Linux (Docker) demo

If you have Docker for Windows with LCOW support enabled,
start [`run-dotnet-docker.cmd`](https://github.com/nil4/ANCM-AnyApp/blob/master/run-dotnet-docker.cmd) in a command prompt.

This will build and deploy `dotnet/TestANCM.csproj` to an Alpine Linux container image,
then start the container under IIS Express/ANCM.

In your browser, you should see similar output to the previous demo, but `HttpContext.User.Identity.Name` will
be empty (an application running in a container cannot use a Windows user handle), while `Header[MS-ASPNETCORE-USER]`
*will* have the correct value.

### Python-under-WSL (failing)

If you have WSL (aka Bash-on-Windows) installed, start `wsl.exe ASPNETCORE_PORT=18000 python/server.py` in a command prompt.
This should run the same Python server script used earlier, but this time under Bash/WSL.

If it works, there will be no output; the Python server waits silently for a request.
Open `http://localhost:18000` in your browser, and you should see the request headers
listed, and server logs for the requests processed.

Stop the server (and Bash) by pressing <kbd>Ctrl+C</kbd>.

Start [`run-python-wsl.cmd`](https://github.com/nil4/ANCM-AnyApp/blob/master/run-python-wsl.cmd) in a command prompt.
For reasons that are unclear, but likely related to IIS Express/ANCM starting processes under
[Windows job objects](https://docs.microsoft.com/en-us/windows/desktop/ProcThread/job-objects)
that may be incompatible with Bash-on-Windows, the same command that runs well interactively,
fails under IIS Express/ANCM.

You will likely see the IIS Express error page (`HTTP Error 502.5 - Process Failure`), with
a cryptic message logged in `python-wsl/python-wsl_<date>_<pid>.log`:

```
Error: 0x80070006
```
