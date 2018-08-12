### ASP.NET Core Module V2, extended for Docker/non-native Windows apps

[nil4/IISIntegration](https://github.com/nil4/IISIntegration) is a fork of Microsoft
[aspnet/IISIntegration](https://github.com/aspnet/IISIntegration/) that adds a new capability
to the ASP.NET Core Module V2 (ANCM V2): passing the authenticated IIS user name to any backend process,
beyond just .NET Core applications.

#### <a name="background"></a>Background

The original ANCM V2 works as a proxy for .NET Core apps; it is an IIS and IIS Express module
that forwards requests to a backend .NET Core application listening on a local port.

When IIS is configured to use Windows authentication, ANCM passes the identity of the user to
the backend application, as a forwarded request header (`MS-ASPNETCORE-WINAUTHTOKEN`).

The header value is a hex number  (e.g. `61E`), representing a Windows handle for the user identity.
This logic is defined in `FORWARDING_HANDLER::GetHeaders` in [AspNetCoreModuleV2/OutOfProcessRequestHandler/forwardinghandler.cpp](https://github.com/aspnet/IISIntegration/blob/8cf39d35924ad875b2af32d8caaddcdfc4b6693b/src/AspNetCoreModuleV2/OutOfProcessRequestHandler/forwardinghandler.cpp#L925)

The backend .NET Core application reads the user token/handle value on every request, and creates
a `WindowsIdentity` from the numeric value, which is used for the duration of the request. In this way,
.NET Core applications are aware of the identity of the user as authenticated by IIS.

This logic is defined in `AuthenticationHandler.GetUser` in
[Microsoft.AspNetCore.Server.IISIntegration/AuthenticationHandler.cs](https://github.com/aspnet/IISIntegration/blob/8cf39d35924ad875b2af32d8caaddcdfc4b6693b/src/Microsoft.AspNetCore.Server.IISIntegration/AuthenticationHandler.cs#L41).

:warning: Note that the handle passed in the request header
[*must always be closed* by the backend process](https://github.com/aspnet/IISIntegration/blob/8cf39d35924ad875b2af32d8caaddcdfc4b6693b/src/Microsoft.AspNetCore.Server.IISIntegration/AuthenticationHandler.cs#L47) to avoid resource leaks.

#### <a name="security"></a>Security

To ensure the user identity is passed securely, ANCM V2 uses a pairing token approach.
First, an environment variable `ASPNETCORE_TOKEN` is set for the backend process at creation time,
containing a random value.

Then, on every request forwarded to the backend process, ANCM V2 sends the same value in
the `MS-ASPNETCORE-Token` header.

To ensure this header (and any other header whose name starts with `MS-ASPNETCORE`) cannot be spoofed
by a malicious client, ANCM V2 [removes all such headers received by IIS](https://github.com/aspnet/IISIntegration/blob/8cf39d35924ad875b2af32d8caaddcdfc4b6693b/src/AspNetCoreModuleV2/OutOfProcessRequestHandler/forwardinghandler.cpp#L887), ensuring only the values it creates *itself* reach the backend app.

Finally, the .NET Core `IISMiddleware` component checks, at the beginning of every request,
that the process-wide [environment variable matches the incoming request header](https://github.com/aspnet/IISIntegration/blob/8cf39d35924ad875b2af32d8caaddcdfc4b6693b/src/Microsoft.AspNetCore.Server.IISIntegration/IISMiddleware.cs#L89), and rejects the request if they don't match.

#### What does the fork do?

The method used by ANCM V2 to pass the user identity to the backend process has two downsides:

- it can [only represent handles of Windows users](https://github.com/aspnet/IISIntegration/blob/8cf39d35924ad875b2af32d8caaddcdfc4b6693b/src/AspNetCoreModuleV2/OutOfProcessRequestHandler/forwardinghandler.cpp#L926), while IIS supports multiple other authentication schemes ([see the *Remarks* section](https://msdn.microsoft.com/en-us/library/ms689371(v=vs.90).aspx));

- it only works for applications that can recreate a Windows identity from the handle value, and use it during a request.

This unfortunately excludes a large variety of applications that *could* run under IIS, *if only*
they were able to receive the identity of the authenticated user. Examples include apps running in
Docker containers, or applications that run on Windows, but have been developed for another web server,
perhaps expecting a `REMOTE_USER` header (like many NodeJS, Java, Ruby or Python apps do.)

The fork implements a few additional options for ANCM V2 that may help.

Commit https://github.com/nil4/IISIntegration/commit/4c445e0f9cf4cd2b1f20e68dea1d97c66fdbec4c adds the
`forwardUserName`, `forwardDomainName` and `forwardUserNameHeader` settings, which can be used to pass
the IIS authenticated user *name* to any backend application.

Commit https://github.com/nil4/IISIntegration/commit/cdbe1b56ff6c4d340fb0f19e4cdbe3637f1c27ce adds the
`disableProcessIdCheck` setting, which allows running Docker applications behind ANCM V2, bypassing the
check that forces the backend application itself (or one of its children) to be listening on the port
configured by the `ASPNETCORE_PORT` environment variable.

Commit https://github.com/nil4/IISIntegration/commit/6659ab4e203875e878fc94f967cd62519536b642 restores
the ANCM feature that replaces `%ASPNETCORE_PORT%` placeholders in the process arguments with the
actual port value. This feature used to be available in earlier ANCM versions, but later 
[regressed during a refactoring](https://github.com/aspnet/AspNetCoreModule/issues/117#issuecomment-311748366).

> :information_source:
> Set `forwardWindowsAuthToken` to `false` to disable the built-in ANCM V2 behaviour of sending the
Windows user *handle* to the backend application.
> This is not a feature of the fork, but **is required to avoid resource leaks** when the backend
application does not close these handles created on every request.

The schema and default values are shown below (the last four settings are implemented by the ANCM fork):

```xml
<aspNetCore processPath="..." arguments="..."
      forwardWindowsAuthToken="false"

      forwardUserName="false"
      forwardUserDomain="true"
      forwardUserNameHeader="MS-ASPNETCORE-USER"
      disableProcessIdCheck="false" />
```

:bulb: Set `forwardUserName` to `true` for ANCM V2 to forward the *name* of the IIS authenticated user
to the backend process, for all of the [supported IIS authentication methods](https://msdn.microsoft.com/en-us/library/ms689371(v=vs.90).aspx).

> :warning:
> The backend application must implement the protocol described in the [security section](#security)
to ensure request header values have not been tampered with by a malicious client.

The forwarded user name includes the domain, if any, (e.g. `DOMAIN\User`).
Set `forwardUserDomain` to `false` to omit the domain and pass only the user name  (e.g. `User`).

The name will be passed to the backend applicatin in the `MS-ASPNETCORE-USER` request header
(see the [security section](#security) for details).
The header name can be overriden by setting the `forwardUserNameHeader` option.

> :information_source:
> When `forwardUserName` is `true`, the header will **always** be set, even when IIS anonymous
authentication is enabled and the user name is empty, so that the backend application can reliably
make authorization decisions based on its value.

When ANCM V2 launches the process specified in  `processPath` and `arguments`, it waits for the process
to start, and then verifies that it (or one of its child processes) actually listens on the port defined
by the `ASPNETCORE_PORT` environment variable. If this does not happen with the startup interval,
ANCM considers the process launch failed; it retries a few times and then aborts.

This ANCM test is a problem for applications running in Docker containers. Docker for Windows containers
are *launched* by `docker.exe`, but they are actually *hosted* by the `com.docker.service` daemon
(a Windows service) which opens the ports that the container exposes. There is no parent-child relationship
between these processes (the former runs interactively, as a user process, and the latter runs as a system service).

Thus, applications running in a container are not detected as listening on the expected port.
Setting the `disableProcessIdCheck` option to `true` tells ANCM to relax the test; it still verifies
that *some* process listens on the expected port, but it no longer requires the process to be the one
it started itself, or one of its children.

> :bulb:
> This repository includes demo use cases for the extended ANCM running various applications
with IIS authentication, including NodeJS, Python and Dockerized applications (Go and ASP.NET Core on Alpine Linux).
