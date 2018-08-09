FROM microsoft/dotnet:2.1-sdk-alpine AS build

  ENV DOTNET_CLI_TELEMETRY_OPTOUT 1
  WORKDIR /src
  COPY TestANCM.csproj Program.cs ./
  RUN dotnet publish -c Release -o out

FROM microsoft/dotnet:2.1-aspnetcore-runtime-alpine AS runtime

  ENV DOTNET_CLI_TELEMETRY_OPTOUT 1
  ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 1
  WORKDIR /app
  COPY --from=build /src/out ./
  ENTRYPOINT ["dotnet", "TestANCM.dll"]