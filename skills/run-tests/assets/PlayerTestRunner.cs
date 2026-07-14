// Temporary script to run Play Mode tests on a standalone player.
// Invoked via run_method_in_unity; results are polled from Logs/PlayerTestResult.txt.
//
// The build does not auto-run the player: PlayerTestBuildModifier removes
// BuildOptions.AutoRunPlayer so that PlayerTestLauncher can launch the player
// with custom command-line arguments instead. The player still reports results
// back to the Editor over PlayerConnection, because BuildOptions.ConnectToHost
// is always baked into test player builds.

using System.IO;
using System.Text;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Callbacks;
using UnityEditor.TestTools;
using UnityEditor.TestTools.TestRunner.Api;
using UnityEngine;

[assembly: TestPlayerBuildModifier(typeof(UnityCodingSkills.RunTests.PlayerTestBuildModifier))]

namespace UnityCodingSkills.RunTests
{
    public static class PlayerTestRunner
    {
        private const string ResultPath = "Logs/PlayerTestResult.txt"; // Relative to the project root

        public static void RunOnStandalonePlayer()
        {
            if (File.Exists(ResultPath))
            {
                File.Delete(ResultPath);
            }

            var api = ScriptableObject.CreateInstance<TestRunnerApi>();
            api.RegisterCallbacks(new Callbacks());
            api.Execute(new ExecutionSettings(new Filter
            {
                testMode = TestMode.PlayMode,
                groupNames = new[] { "MyNamespace\\.MyTestClass" }, // Same regex semantics as run_unity_tests
                targetPlatform = BuildTarget.StandaloneOSX // Match the host OS (see the table in run-on-standalone-player.md)
            })
            {
                overloadTestRunSettings = new PlayerTestBuildSettings()
            });
        }

        private class Callbacks : ICallbacks
        {
            public void RunStarted(ITestAdaptor testsToRun)
            {
            }

            public void RunFinished(ITestResultAdaptor result)
            {
                var builder = new StringBuilder();
                builder.AppendLine(
                    $"pass:{result.PassCount} fail:{result.FailCount} skip:{result.SkipCount} inconclusive:{result.InconclusiveCount}");
                AppendFailures(result, builder);
                Directory.CreateDirectory("Logs"); // Logs/ may have been cleaned up during the minutes-long build
                File.WriteAllText(ResultPath, builder.ToString());
            }

            public void TestStarted(ITestAdaptor test)
            {
            }

            public void TestFinished(ITestResultAdaptor result)
            {
            }

            private static void AppendFailures(ITestResultAdaptor result, StringBuilder builder)
            {
                if (result.Test.IsSuite)
                {
                    foreach (var child in result.Children)
                    {
                        AppendFailures(child, builder);
                    }
                }
                else if (result.TestStatus == TestStatus.Failed)
                {
                    builder.AppendLine($"FAILED: {result.FullName}");
                    builder.AppendLine(result.Message);
                }
            }
        }
    }

    public class PlayerTestBuildSettings : ITestRunSettings
    {
        // Filled with the project's own PlayerSettings values (fetched with
        // get-player-settings.sh — see run-on-standalone-player.md step 1), so the test build
        // matches the project configuration; replace a value only when the user
        // specifies a different one. Notes: ManagedStrippingLevel.Disabled is a
        // Mono-only option — under IL2CPP, Unity treats it as Minimal. Stripping
        // above Disabled can break reflection-based assertions — see "Reflection-
        // based assertion fails only on Player" in run-on-standalone-player.md.
        private const ScriptingImplementation ScriptingBackend = ScriptingImplementation.Mono2x;
        private const Il2CppCodeGeneration CodeGeneration = Il2CppCodeGeneration.OptimizeSpeed;
        private const ManagedStrippingLevel StrippingLevel = ManagedStrippingLevel.Disabled;

        private ScriptingImplementation _originalScriptingBackend;
        private Il2CppCodeGeneration _originalCodeGeneration;
        private ManagedStrippingLevel _originalStrippingLevel;

        // Called before the player build; overrides are baked into the build
        public void Apply()
        {
            _originalScriptingBackend = PlayerSettings.GetScriptingBackend(NamedBuildTarget.Standalone);
            _originalCodeGeneration = PlayerSettings.GetIl2CppCodeGeneration(NamedBuildTarget.Standalone);
            _originalStrippingLevel = PlayerSettings.GetManagedStrippingLevel(NamedBuildTarget.Standalone);
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Standalone, ScriptingBackend);
            PlayerSettings.SetIl2CppCodeGeneration(NamedBuildTarget.Standalone, CodeGeneration);
            PlayerSettings.SetManagedStrippingLevel(NamedBuildTarget.Standalone, StrippingLevel);
        }

        // Called after the player build; restores the project settings
        public void Dispose()
        {
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Standalone, _originalScriptingBackend);
            PlayerSettings.SetIl2CppCodeGeneration(NamedBuildTarget.Standalone, _originalCodeGeneration);
            PlayerSettings.SetManagedStrippingLevel(NamedBuildTarget.Standalone, _originalStrippingLevel);
        }
    }

    public class PlayerTestBuildModifier : ITestPlayerBuildModifier
    {
        // Match the host OS: ".app" on macOS, ".exe" on Windows, no extension on Linux
        internal const string BuildLocation = "Temp/PlayerWithTests/PlayerWithTests.app";

        public BuildPlayerOptions ModifyOptions(BuildPlayerOptions playerOptions)
        {
            // Auto-run cannot pass arguments to the player, so PlayerTestLauncher launches it instead
            playerOptions.options &= ~BuildOptions.AutoRunPlayer;
            playerOptions.locationPathName = BuildLocation;
            return playerOptions;
        }
    }

    public static class PlayerTestLauncher
    {
        // Defaults are the project's own screen settings passed explicitly, because a
        // previously launched player persists its resolution in PlayerPrefs, which would
        // otherwise win over the project defaults. See "Player command-line arguments"
        // in run-on-standalone-player.md.
        private const string PlayerArguments = "-screen-fullscreen 0 -screen-width 1920 -screen-height 1080";

        [PostProcessBuild]
        public static void OnPostprocessBuild(BuildTarget target, string pathToBuiltProject)
        {
            if (Path.GetFullPath(pathToBuiltProject) != Path.GetFullPath(PlayerTestBuildModifier.BuildLocation))
            {
                return; // Not the test player build
            }

            if (Application.platform == RuntimePlatform.OSXEditor)
            {
                // A .app bundle is not directly executable; 'open' resolves the binary inside it
                System.Diagnostics.Process.Start("open", $"-n \"{pathToBuiltProject}\" --args {PlayerArguments}");
            }
            else
            {
                System.Diagnostics.Process.Start(Path.GetFullPath(pathToBuiltProject), PlayerArguments);
            }
        }
    }
}
