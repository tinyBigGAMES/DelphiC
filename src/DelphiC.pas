{===============================================================================
  ___      _      _    _  ___™
 |   \ ___| |_ __| |_ (_)/ __|
 | |) / -_) | '_ \ ' \| | (__
 |___/\___|_| .__/_||_|_|\___|
            |_|
 Runtime C compilation for Delphi

 Copyright © 2025-present tinyBigGAMES™ LLC
 All Rights Reserved.

 https://github.com/tinyBigGAMES/DelphiC

 BSD 3-Clause License

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 ------------------------------------------------------------------------------

 This library uses the following open-source libraries:
   * tinycc  - https://github.com/kyx0r/tinycc

===============================================================================}

unit DelphiC;

interface

uses
  WinApi.Windows,
  System.Generics.Collections,
  System.SysUtils,
  System.Classes,
  System.Math;

const
  /// <summary>
  ///   Major version number of the DelphiC library.
  /// </summary>
  /// <remarks>
  ///   Incremented for breaking changes or major feature additions.
  /// </remarks>
  DC_MAJOR_VERSION = 1;

  /// <summary>
  ///   Minor version number of the DelphiC library.
  /// </summary>
  /// <remarks>
  ///   Incremented for new features that maintain backward compatibility.
  /// </remarks>
  DC_MINOR_VERSION = 0;

  /// <summary>
  ///   Patch version number of the DelphiC library.
  /// </summary>
  /// <remarks>
  ///   Incremented for bug fixes and minor improvements.
  /// </remarks>
  DC_PATCH_VERSION = 0;

type
  /// <summary>
  ///   Defines the output type for TCC compilation. Maps directly to TCC_OUTPUT_* constants.
  /// </summary>
  TDCOutput = (
    /// <summary>
    ///   Compile to memory for runtime execution and symbol access.
    /// </summary>
    /// <remarks>
    ///   Enables GetSymbol after Relocate. Code runs directly in memory without file output.
    /// </remarks>
    opMemory=1,

    /// <summary>
    ///   Generate executable file.
    /// </summary>
    /// <remarks>
    ///   Enables Run and OutputFile. Creates standalone executable program.
    /// </remarks>
    opEXE=2,

    /// <summary>
    ///   Generate object file.
    /// </summary>
    /// <remarks>
    ///   Enables OutputFile only. Creates .o/.obj file for later linking.
    /// </remarks>
    opOBJ=3,

    /// <summary>
    ///   Generate dynamic library.
    /// </summary>
    /// <remarks>
    ///   Enables OutputFile only. Creates .dll/.so shared library file.
    /// </remarks>
    opDLL=4,

    /// <summary>
    ///   Only run preprocessor.
    /// </summary>
    /// <remarks>
    ///   Preprocessing only, no compilation or linking. Outputs preprocessed source.
    /// </remarks>
    opPreProcess=5
  );

  /// <summary>
  ///   Callback procedure for TCC error and warning messages.
  /// </summary>
  /// <param name="AError">The error or warning message from TCC</param>
  /// <param name="AUserData">User-defined data pointer passed during callback registration</param>
  TDCPrintCallback = reference to procedure(const AError: string; const AUserData: Pointer);

  /// <summary>
  ///   Classification of compiler diagnostic message severity levels.
  /// </summary>
  /// <remarks>
  ///   Used by TDCError to categorize messages from the TCC error callback.
  ///   TCC emits both compilation errors that prevent code generation and
  ///   warnings about potential issues.
  /// </remarks>
  TDCErrorType = (
    /// <summary>
    ///   Compilation error that prevents successful code generation.
    /// </summary>
    etError,

    /// <summary>
    ///   Warning about potential issues that don't prevent compilation.
    /// </summary>
    etWarning,

    /// <summary>
    ///   Informational note providing additional context about errors or warnings.
    /// </summary>
    etNote
  );

  /// <summary>
  ///   Represents a structured compiler diagnostic message (error, warning, or note).
  /// </summary>
  /// <remarks>
  ///   <para>
  ///     Provides parsed information from TCC's text-based error callback output.
  ///     TCC emits messages in the format: "filename:line: type: message"
  ///   </para>
  ///   <para>
  ///     Retrieved via GetErrors() after compilation attempts. The error list
  ///     accumulates messages until ClearErrors() is called or the compiler is reset.
  ///   </para>
  /// </remarks>
  TDCError = record
    /// <summary>
    ///   Source filename where the diagnostic was reported.
    /// </summary>
    /// <remarks>
    ///   For code compiled via CompileString, this reflects the filename parameter
    ///   passed to that method (default: 'source.c').
    /// </remarks>
    Filename: string;

    /// <summary>
    ///   Line number in the source file where the diagnostic occurred.
    /// </summary>
    /// <remarks>
    ///   Zero if line number could not be parsed from the error message.
    ///   Uses 1-based indexing (first line is 1, not 0).
    /// </remarks>
    Line: Integer;

    /// <summary>
    ///   The diagnostic message text from the compiler.
    /// </summary>
    /// <remarks>
    ///   Contains the descriptive text after the "error:" or "warning:" prefix
    ///   in TCC's output. May include additional context or suggestions.
    /// </remarks>
    Message: string;

    /// <summary>
    ///   Classification of the diagnostic severity (error, warning, or note).
    /// </summary>
    /// <remarks>
    ///   Determined by parsing TCC's message prefix. Errors prevent successful
    ///   compilation while warnings indicate potential issues but allow code generation.
    /// </remarks>
    ErrorType: TDCErrorType;
  end;

  /// <summary>
  ///   Windows PE subsystem types for executable output.
  /// </summary>
  TDCSubsystem = (
    /// <summary>
    ///   Console application with command-line window (default).
    /// </summary>
    ssConsole,

    /// <summary>
    ///   GUI application without console window.
    /// </summary>
    ssGUI
  );

  /// <summary>
  ///   High-level wrapper class for the Tiny C Compiler (TCC) library that provides
  ///   safe, workflow-enforced access to TCC functionality with automatic state management.
  /// </summary>
  /// <remarks>
  ///   <para>
  ///     TDelphiC enforces the correct TCC API workflow to prevent common usage errors
  ///     that can cause crashes or undefined behavior. The class manages internal state
  ///     transitions and validates method calls based on current workflow state.
  ///   </para>
  ///   <para>
  ///     <b>Memory Output Workflow:</b>
  ///     SetOutput(opMemory) → Configure → CompileString → AddSymbol → Relocate → GetSymbol
  ///   </para>
  ///   <para>
  ///     <b>File Output Workflow:</b>
  ///     SetOutput(opEXE/opDLL/opOBJ) → Configure → CompileString → AddSymbol → OutputFile
  ///   </para>
  ///   <para>
  ///     <b>Execute Workflow:</b>
  ///     SetOutput(opEXE) → Configure → CompileString → AddSymbol → Run
  ///   </para>
  /// </remarks>
  /// <example>
  ///   <code lang="delphi">
  ///   var
  ///     LCompiler: TDelphiC;
  ///     LMainFunc: function(): Integer; cdecl;
  ///   begin
  ///     LCompiler := TDelphiC.Create();
  ///     try
  ///       // Configure for memory execution
  ///       LCompiler.SetOutput(opMemory);
  ///       LCompiler.DefineSymbol('VERSION', '100');
  ///
  ///       // Compile C code
  ///       if LCompiler.CompileString('int main() { return VERSION; }', 'test.c') then
  ///       begin
  ///         // Relocate and get symbol
  ///         if LCompiler.Relocate() then
  ///         begin
  ///           LMainFunc := LCompiler.GetSymbol('main');
  ///           if Assigned(LMainFunc) then
  ///             WriteLn('Result: ', LMainFunc());
  ///         end;
  ///       end;
  ///     finally
  ///       LCompiler.Free;
  ///     end;
  ///   end;
  ///   </code>
  /// </example>
  TDelphiC = class
  protected type
    { TWorkflowState }
    TWorkflowState = (wsNew, wsConfigured, wsCompiled, wsRelocated, wsFinalized);

    { TCallback }
    TCallback<T> = record
      Handler: T;
      UserData: Pointer;
    end;
  protected
    FMarshaller: TMarshaller;
    FState: Pointer;
    FWorkflowState: TWorkflowState;
    FOutput: TDCOutput;
    FOutputSet: Boolean;
    FPrintCallback: TCallback<TDCPrintCallback>;
    FErrors: TList<TDCError>;

    function AsUTF8(const AText: string): Pointer;
    procedure InternalPrintCallback(const AError: string; const AUserData: Pointer);

    procedure NewState();
    procedure FreeState();

  public
    /// <summary>
    ///   Creates a new TDelphiC instance and initializes the TCC compilation context.
    /// </summary>
    /// <exception cref="Exception">Raised if TCC initialization fails</exception>
    constructor Create(); virtual;

    /// <summary>
    ///   Destroys the TDelphiC instance and releases all TCC resources.
    /// </summary>
    destructor Destroy(); override;

    /// <summary>
    ///   Returns the DelphiC library version as a formatted string.
    /// </summary>
    /// <returns>
    ///   Version string in semantic versioning format "MAJOR.MINOR.PATCH" (e.g., "1.0.0").
    /// </returns>
    /// <remarks>
    ///   Combines DC_MAJOR_VERSION, DC_MINOR_VERSION, and DC_PATCH_VERSION constants
    ///   into a single readable version string following semantic versioning conventions.
    /// </remarks>
    class function GetVersionStr(): string; static;

    /// <summary>
    ///   Returns all captured errors and warnings from last compilation.
    /// </summary>
    function GetErrors(): TArray<TDCError>;

    /// <summary>
    ///   Clears the error list.
    /// </summary>
    procedure ClearErrors();

    /// <summary>
    ///   Resets the compiler to initial state, destroying and recreating the TCC context.
    /// </summary>
    /// <remarks>
    ///   This allows reuse of the same TDelphiC instance for multiple compilation sessions.
    ///   All previous configuration, compilation state, and symbols are lost.
    /// </remarks>
    /// <exception cref="Exception">Raised if TCC reinitialization fails</exception>
    procedure Reset();

    /// <summary>
    ///   Sets a callback function to receive TCC error and warning messages.
    /// </summary>
    /// <param name="AUserData">User-defined pointer passed to callback function</param>
    /// <param name="AHandler">Callback procedure to handle messages</param>
    /// <remarks>
    ///   The callback can be set at any time and will receive all subsequent TCC messages.
    ///   Pass nil for AHandler to disable callback.
    /// </remarks>
    procedure SetPrintCallback(const AUserData: Pointer; const AHandler: TDCPrintCallback);

    /// <summary>
    ///   Triggers the print callback with a formatted message (for testing/debugging).
    /// </summary>
    /// <param name="AText">Format string for the message</param>
    /// <param name="AArgs">Arguments for string formatting</param>
    /// <remarks>
    ///   This method is primarily for testing callback functionality. In normal usage,
    ///   TCC will call the callback automatically for errors and warnings.
    /// </remarks>
    procedure Print(const AText: string; const AArgs: array of const);

    /// <summary>
    ///   Adds a directory to the include file search path.
    /// </summary>
    /// <param name="APathName">Directory path to add to include search path</param>
    /// <returns>True if successful, False if operation failed or called at wrong time</returns>
    /// <remarks>
    ///   Can only be called before compilation starts.
    ///   Equivalent to TCC's -I command line option.
    /// </remarks>
    function AddIncludePath(const APathName: string): Boolean;

    /// <summary>
    ///   Adds a directory to the system include file search path.
    /// </summary>
    /// <param name="APathName">Directory path to add to system include search path</param>
    /// <returns>True if successful, False if operation failed or called at wrong time</returns>
    /// <remarks>
    ///   Can only be called before compilation starts.
    ///   System include paths are searched after regular include paths.
    /// </remarks>
    function AddSystemIncludePath(const APathName: string): Boolean;

    /// <summary>
    ///   Adds a directory to the library search path.
    /// </summary>
    /// <param name="APathName">Directory path to add to library search path</param>
    /// <returns>True if successful, False if operation failed or called at wrong time</returns>
    /// <remarks>
    ///   Can only be called before compilation starts.
    ///   Equivalent to TCC's -L command line option.
    /// </remarks>
    function AddLibraryPath(const APathName: string): Boolean;

    /// <summary>
    ///   Links a library with the compiled program.
    /// </summary>
    /// <param name="ALibraryName">Name of library to link (without lib prefix or extension)</param>
    /// <returns>True if successful, False if operation failed or called at wrong time</returns>
    /// <remarks>
    ///   Can only be called before compilation starts.
    ///   Equivalent to TCC's -l command line option. For example, 'math' links libmath.a/math.dll.
    /// </remarks>
    function AddLibrary(const ALibraryName: string): Boolean;

    /// <summary>
    ///   Defines a preprocessor symbol with optional value.
    /// </summary>
    /// <param name="ASymbol">Symbol name to define, can include value like 'NAME=value'</param>
    /// <param name="AValue">Value for the symbol, can be empty</param>
    /// <returns>True if successful, False if called at wrong time</returns>
    /// <remarks>
    ///   Can only be called before compilation starts.
    ///   Equivalent to TCC's -D command line option. If AValue is empty, symbol is defined without value.
    /// </remarks>
    function DefineSymbol(const ASymbol, AValue: string): Boolean;

    /// <summary>
    ///   Undefines a previously defined preprocessor symbol.
    /// </summary>
    /// <param name="ASymbol">Symbol name to undefine</param>
    /// <returns>True if successful, False if called at wrong time</returns>
    /// <remarks>
    ///   Can only be called before compilation starts.
    ///   Equivalent to TCC's -U command line option.
    /// </remarks>
    function UndefineSymbol(const ASymbol: string): Boolean;

    /// <summary>
    ///   Sets the compilation output type. MUST be called before any compilation.
    /// </summary>
    /// <param name="AOutput">Output type specifying compilation target</param>
    /// <returns>True if successful, False if operation failed or called at wrong time</returns>
    /// <remarks>
    ///   <para>Must be called first before any other operations. This determines the compilation workflow:</para>
    ///   <list type="bullet">
    ///     <item>opMemory: Enables GetSymbol after Relocate</item>
    ///     <item>opEXE: Enables Run and OutputFile</item>
    ///     <item>opDLL/opOBJ: Enables OutputFile only</item>
    ///     <item>opPreProcess: Preprocessing only</item>
    ///   </list>
    /// </remarks>
    function SetOuput(const AOutput: TDCOutput): Boolean;

    /// <summary>
    ///   Sets a TCC command-line option directly.
    /// </summary>
    /// <param name="AOption">TCC option string (e.g., "-w", "-g", "-Werror")</param>
    /// <returns>True if option accepted, False if invalid or called at wrong time</returns>
    /// <remarks>
    ///   <para>Maps directly to tcc_set_options(). Can be called multiple times.</para>
    ///   <para>Must be called after SetOutput but before compilation.</para>
    ///   <para><b>Valid options for Win64 TCC:</b></para>
    ///   <para><b>Preprocessor Options:</b></para>
    ///   <list type="bullet">
    ///     <item><c>-Idir</c> - Add include path (searched before system paths)</item>
    ///     <item><c>-Dsym[=val]</c> - Define preprocessor symbol (val defaults to 1). Example: -DVERSION=100 or -DF(a)=a+1</item>
    ///     <item><c>-Usym</c> - Undefine preprocessor symbol</item>
    ///     <item><c>-E</c> - Preprocess only, output to stdout or file (with -o)</item>
    ///   </list>
    ///   <para><b>Compilation Flags:</b></para>
    ///   <list type="bullet">
    ///     <item><c>-funsigned-char</c> - Make char type unsigned (default is signed)</item>
    ///     <item><c>-fsigned-char</c> - Make char type signed (default)</item>
    ///     <item><c>-fno-common</c> - Don't generate common symbols for uninitialized data</item>
    ///     <item><c>-fleading-underscore</c> - Add leading underscore to C symbols</item>
    ///     <item><c>-fms-extensions</c> - Allow MS C compiler language extensions</item>
    ///     <item><c>-fdollars-in-identifiers</c> - Allow $ in identifiers</item>
    ///   </list>
    ///   <para><b>Warning Options:</b></para>
    ///   <list type="bullet">
    ///     <item><c>-w</c> - Disable all warnings</item>
    ///     <item><c>-Wimplicit-function-declaration</c> - Warn about implicit function declarations</item>
    ///     <item><c>-Wunsupported</c> - Warn about unsupported GCC features</item>
    ///     <item><c>-Wwrite-strings</c> - Make string constants const char* instead of char*</item>
    ///     <item><c>-Werror</c> - Treat all warnings as errors (abort compilation)</item>
    ///     <item><c>-Wall</c> - Enable all warnings except -Werror, -Wunsupported, -Wwrite-strings</item>
    ///     <item><c>-Wno-xxx</c> - Disable specific warning (e.g., -Wno-implicit-function-declaration)</item>
    ///   </list>
    ///   <para><b>Linker Options:</b></para>
    ///   <list type="bullet">
    ///     <item><c>-Ldir</c> - Add library search path for -l option</item>
    ///     <item><c>-lxxx</c> - Link with library xxx.lib or xxx.dll</item>
    ///     <item><c>-Bdir</c> - Set path for TCC internal libraries</item>
    ///     <item><c>-Wl,-subsystem=console</c> - Create console application (default)</item>
    ///     <item><c>-Wl,-subsystem=gui</c> - Create GUI application (no console window)</item>
    ///     <item><c>-Wl,-subsystem=wince</c> - Create Windows CE application</item>
    ///     <item><c>-Wl,-stack=size</c> - Set stack size in bytes</item>
    ///     <item><c>-Wl,-image-base=addr</c> - Set base address for executable</item>
    ///     <item><c>-Wl,-file-alignment=size</c> - Set PE file alignment</item>
    ///     <item><c>-Wl,-section-alignment=size</c> - Set PE section alignment</item>
    ///   </list>
    ///   <para><b>Debugger Options:</b></para>
    ///   <list type="bullet">
    ///     <item><c>-g</c> - Generate debug information for detailed runtime error messages</item>
    ///   </list>
    ///   <para><b>Target-Specific Options:</b></para>
    ///   <list type="bullet">
    ///     <item><c>-mms-bitfields</c> - Use MSVC bitfield alignment (recommended for Win64)</item>
    ///     <item><c>-mno-sse</c> - Don't use SSE registers on x86_64</item>
    ///   </list>
    ///   <para><b>Misc Options:</b></para>
    ///   <list type="bullet">
    ///     <item><c>-MD</c> - Generate makefile fragment with dependencies</item>
    ///     <item><c>-MF depfile</c> - Use depfile as output for -MD</item>
    ///   </list>
    ///   <para><b>Note:</b> Optimization flags (-O0, -O1, etc.) are ignored. Bounds checking (-b) is not available on Win64.</para>
    /// </remarks>
    /// <example>
    ///   <code lang="delphi">
    ///   LCompiler.SetOption('-g');                      // Enable debug info
    ///   LCompiler.SetOption('-Wall');                   // Enable warnings
    ///   LCompiler.SetOption('-DVERSION=100');           // Define VERSION macro
    ///   LCompiler.SetOption('-IC:\MyProject\include');  // Add include path
    ///   LCompiler.SetOption('-luser32');                // Link Windows API library
    ///   LCompiler.SetOption('-Wl,-subsystem=console');  // Console application
    ///   LCompiler.SetOption('-mms-bitfields');          // MSVC compatibility
    ///   </code>
    /// </example>
    function SetOption(const AOption: string): Boolean;

    /// <summary>
    ///   Sets the Windows subsystem type for PE executable output.
    /// </summary>
    /// <param name="ASubsystem">Subsystem type (console or GUI)</param>
    /// <returns>True if successful</returns>
    /// <remarks>
    ///   <para>Only valid for opEXE or opDLL output types.</para>
    ///   <para>Must be called after SetOutput but before compilation.</para>
    ///   <para>Console is the default if not specified.</para>
    ///   <para>If called multiple times, the last call wins.</para>
    /// </remarks>
    function SetSubsystem(const ASubsystem: TDCSubsystem): Boolean;

    /// <summary>
    ///   Enables runtime debug information for detailed error messages.
    /// </summary>
    /// <param name="AEnabled">True to enable debug info (-g flag)</param>
    /// <returns>True if successful</returns>
    /// <remarks>
    ///   With -g: "test.c:68: in function 'test5()': dereferencing invalid pointer"
    ///   Without: "Segmentation fault"
    /// </remarks>
    function SetDebugInfo(const AEnabled: Boolean): Boolean;

    /// <summary>
    ///   Disables all compiler warnings.
    /// </summary>
    /// <returns>True if successful</returns>
    function DisableWarnings(): Boolean;

    /// <summary>
    ///   Treats all warnings as compilation errors.
    /// </summary>
    /// <returns>True if successful</returns>
    function SetWarningsAsErrors(): Boolean;

    /// <summary>
    ///   Makes char type unsigned by default.
    /// </summary>
    /// <returns>True if successful</returns>
    function SetUnsignedChar(): Boolean;

    /// <summary>
    ///   Makes char type signed by default (TCC default).
    /// </summary>
    /// <returns>True if successful</returns>
    function SetSignedChar(): Boolean;

    /// <summary>
    ///   Compiles C source code from a string with optional filename for error reporting.
    /// </summary>
    /// <param name="ACode">C source code to compile</param>
    /// <param name="AFilename">Filename for error reporting (default: 'source.c')</param>
    /// <returns>True if compilation successful, False if errors occurred</returns>
    /// <remarks>
    ///   <para>Can only be called after SetOutput. Automatically prepends #line directive for better error reporting.</para>
    ///   <para>Multiple calls can add more source code to the same compilation unit.</para>
    /// </remarks>
    function CompileString(const ACode: string; const AFilename: string='source.c'): Boolean;

    /// <summary>
    ///   Compiles a C source file (.c or .h).
    /// </summary>
    /// <param name="AFilename">Path to C source file</param>
    /// <returns>True if compilation successful, False if errors occurred</returns>
    /// <remarks>
    ///   Convenience wrapper around AddFile that clarifies intent for source compilation.
    ///   For object files or libraries, use AddFile directly.
    /// </remarks>
    function CompileFile(const AFilename: string): Boolean;

    /// <summary>
    ///   Adds a file to the compilation (C source, object, library, or linker script).
    /// </summary>
    /// <param name="AFilename">Path to the file to add</param>
    /// <returns>True if file added successfully, False if failed or called at wrong time</returns>
    /// <remarks>
    ///   <para>Can only be called after SetOutput and before finalization.</para>
    ///   <para>Supports multiple file types:</para>
    ///   <list type="bullet">
    ///     <item>C source files (.c, .h) - compiled into the program</item>
    ///     <item>Object files (.o, .obj) - linked into the program</item>
    ///     <item>Libraries (.a, .lib) - linked into the program</item>
    ///     <item>DLLs (.dll, .so) - linked into the program</item>
    ///     <item>Linker scripts (.ld) - used during linking</item>
    ///   </list>
    ///   <para>Multiple files can be added by calling this method multiple times.</para>
    /// </remarks>
    function AddFile(const AFilename: string): Boolean;

    /// <summary>
    ///   Generates output file (executable, library, or object file).
    /// </summary>
    /// <param name="AFilename">Output filename with appropriate extension</param>
    /// <returns>True if file generation successful, False if failed</returns>
    /// <remarks>
    ///   <para>Can only be called after compilation for non-memory output types.</para>
    ///   <para>Cannot be called after Relocate() - violates TCC API requirements.</para>
    ///   <para>No further operations possible after this call.</para>
    /// </remarks>
    function OutputFile(const AFilename: string): Boolean;

    /// <summary>
    ///   Executes the compiled program's main() function directly in memory.
    /// </summary>
    /// <param name="AArgc">Argument count (argc parameter to main)</param>
    /// <param name="AArgv">Pointer to argument array (argv parameter to main)</param>
    /// <returns>Return value from main() function, or -1 if execution failed</returns>
    /// <remarks>
    ///   <para>Can only be called after compilation for executable output type.</para>
    ///   <para>Cannot be called after Relocate() - violates TCC API requirements.</para>
    ///   <para>No further operations possible after this call.</para>
    /// </remarks>
    function Run(const AArgc: Integer; const AArgv: Pointer): Integer;

    /// <summary>
    ///   Performs memory relocation for in-memory execution (required before GetSymbol).
    /// </summary>
    /// <returns>True if relocation successful, False if failed</returns>
    /// <remarks>
    ///   <para>Can only be called after compilation for memory output type.</para>
    ///   <para>Required before GetSymbol can be used to retrieve function/variable pointers.</para>
    ///   <para>After relocation, no OutputFile or Run operations are allowed.</para>
    /// </remarks>
    function Relocate(): Boolean;

    /// <summary>
    ///   Adds a symbol (function or variable) to the compiled program's symbol table.
    /// </summary>
    /// <param name="AName">Symbol name as it appears in C code</param>
    /// <param name="AValue">Pointer to the function or variable</param>
    /// <returns>True if symbol added successfully, False if failed or called at wrong time</returns>
    /// <remarks>
    ///   <para>Can only be called after compilation, before Relocate for memory output.</para>
    ///   <para>Allows C code to call Delphi functions or access Delphi variables.</para>
    ///   <para>For functions, use @FunctionName to get the pointer.</para>
    /// </remarks>
    /// <example>
    ///   <code lang="delphi">
    ///   function MyCallback(x: Integer): Integer; cdecl;
    ///   begin
    ///     Result := x * 2;
    ///   end;
    ///
    ///   // Later in code:
    ///   LCompiler.AddSymbol('my_callback', @MyCallback);
    ///   </code>
    /// </example>
    function AddSymbol(const AName: string; const AValue: Pointer): Boolean;

    /// <summary>
    ///   Retrieves a symbol (function or variable) pointer from the compiled program.
    /// </summary>
    /// <param name="AName">Symbol name to retrieve</param>
    /// <returns>Pointer to the symbol, or nil if not found or called at wrong time</returns>
    /// <remarks>
    ///   <para>Can only be called after successful Relocate for memory output.</para>
    ///   <para>Use type casting to convert the pointer to appropriate function or variable type.</para>
    ///   <para>Returned pointers remain valid until object is destroyed or Reset is called.</para>
    /// </remarks>
    /// <example>
    ///   <code lang="delphi">
    ///   type
    ///     TMainFunc = function(): Integer; cdecl;
    ///   var
    ///     LMainFunc: TMainFunc;
    ///   begin
    ///     LMainFunc := TMainFunc(LCompiler.GetSymbol('main'));
    ///     if Assigned(LMainFunc) then
    ///       WriteLn('Result: ', LMainFunc());
    ///   end;
    ///   </code>
    /// </example>
    function GetSymbol(const AName: string): Pointer;
  end;

implementation

{$REGION ' TCC '}
const
  TCC_OUTPUT_MEMORY     = 1;
  TCC_OUTPUT_EXE        = 2;
  TCC_OUTPUT_DLL        = 4;
  TCC_OUTPUT_OBJ        = 3;
  TCC_OUTPUT_PREPROCESS = 5;

type
  TCCState = type Pointer;
  TCCReallocFunc = function(ptr: Pointer; size: Cardinal): Pointer; cdecl;
  TCCErrorFunc = procedure(opaque: Pointer; msg: PAnsiChar); cdecl;
  TCCSymbolCallback = procedure(ctx: Pointer; name: PAnsiChar; val: Pointer); cdecl;
  TCCBtFunc = function(udata, pc: Pointer; file_: PAnsiChar; line: Integer; func, msg: PAnsiChar): Integer; cdecl;

var
  tcc_set_realloc: procedure(my_realloc: TCCReallocFunc); cdecl;
  tcc_new: function(): TCCState; cdecl;
  tcc_delete: procedure(s: TCCState); cdecl;
  tcc_set_lib_path: procedure(s: TCCState; path: PAnsiChar); cdecl;
  tcc_set_error_func: procedure(s: TCCState; error_opaque: Pointer; error_func: TCCErrorFunc); cdecl;
  tcc_set_options: function(s: TCCState; str: PAnsiChar): Integer; cdecl;
  tcc_add_include_path: function(s: TCCState; pathname: PAnsiChar): Integer; cdecl;
  tcc_add_sysinclude_path: function(s: TCCState; pathname: PAnsiChar): Integer; cdecl;
  tcc_define_symbol: procedure(s: TCCState; sym, value: PAnsiChar); cdecl;
  tcc_undefine_symbol: procedure(s: TCCState; sym: PAnsiChar); cdecl;
  tcc_add_file: function(s: TCCState; filename: PAnsiChar): Integer; cdecl;
  tcc_compile_string: function(s: TCCState; buf: PAnsiChar): Integer; cdecl;
  tcc_set_output_type: function(s: TCCState; output_type: Integer): Integer; cdecl;
  tcc_add_library_path: function(s: TCCState; pathname: PAnsiChar): Integer; cdecl;
  tcc_add_library: function(s: TCCState; libraryname: PAnsiChar): Integer; cdecl;
  tcc_add_symbol: function(s: TCCState; name: PAnsiChar; val: Pointer): Integer; cdecl;
  tcc_output_file: function(s: TCCState; filename: PAnsiChar): Integer; cdecl;
  tcc_run: function(s: TCCState; argc: Integer; argv: PPAnsiChar): Integer; cdecl;
  tcc_relocate: function(s1: TCCState): Integer; cdecl;
  tcc_get_symbol: function(s: TCCState; name: PAnsiChar): Pointer; cdecl;
  tcc_list_symbols: procedure(s: TCCState; ctx: Pointer; symbol_cb: TCCSymbolCallback); cdecl;
  tcc_set_backtrace_func: procedure(s1: TCCState; userdata: Pointer; bt: TCCBtFunc); cdecl;
{$ENDREGION}

{$REGION ' DelphiC '}

{ TDelphiC }
procedure DC_TCCErrorFunc(AOpaque: Pointer; AMsg: PAnsiChar); cdecl;
var
  LSelf: TDelphiC;
begin
  LSelf := AOpaque;
  if not Assigned(LSelf) then Exit;
  //LSelf.Print(string(AMsg), []);
  LSelf.InternalPrintCallback(string(AMsg), AOpaque);
end;

function DC_TCCReallocFunc(APtr: Pointer; ASize: Cardinal): Pointer; cdecl;
begin
  // Custom memory reallocation logic
  if ASize = 0 then
  begin
    // Free memory when size is 0
    if APtr <> nil then
      FreeMem(APtr);
    Result := nil;
  end
  else if APtr = nil then
  begin
    // Allocate new memory when pointer is nil
    GetMem(Result, ASize);
  end
  else
  begin
    // Reallocate existing memory
    ReallocMem(APtr, ASize);
    Result := APtr;
  end;

  // Optionally, log what happens
  (*
  OutputDebugString(PChar(Format('MyRealloc called: Ptr=%p Size=%d -> %p',
    [APtr, ASize, Result])));
  *)
end;

function TDelphiC.AsUTF8(const AText: string): Pointer;
begin
  Result := FMarshaller.AsUtf8(AText).ToPointer;
end;

procedure TDelphiC.InternalPrintCallback(const AError: string; const AUserData: Pointer);
var
  LError: TDCError;
  LParts: TArray<string>;
begin
  // Parse TCC error format: "filename:line: error: message"
  // or "filename:line: warning: message"

  LParts := AError.Split([':'], 4);

  if Length(LParts) >= 3 then
  begin
    LError.Filename := LParts[0].Trim;
    LError.Line := StrToIntDef(LParts[1].Trim, 0);

    // Determine error type
    if LParts[2].Trim.ToLower.Contains('error') then
      LError.ErrorType := etError
    else if LParts[2].Trim.ToLower.Contains('warning') then
      LError.ErrorType := etWarning
    else
      LError.ErrorType := etNote;

    // Get message (everything after "error:" or "warning:")
    if Length(LParts) > 3 then
      LError.Message := LParts[3].Trim
    else
      LError.Message := LParts[2].Trim;

    FErrors.Add(LError);
  end;

  // Also call user's callback if they set one
  if Assigned(FPrintCallback.Handler) then
    FPrintCallback.Handler(AError, FPrintCallback.UserData);
end;

procedure TDelphiC.NewState();
begin
  tcc_set_realloc(DC_TCCReallocFunc);

  if not Assigned(FState) then
  begin
  FState := tcc_new();
  if not Assigned(FState) then
    raise Exception.Create('Failed to create tcc state');
  end;

  FWorkflowState := wsNew;
  FOutputSet := False;
  ClearErrors();

  tcc_set_error_func(FState, Self, DC_TCCErrorFunc);
end;

procedure TDelphiC.FreeState();
begin
  if Assigned(FState) then
  begin
    tcc_delete(FState);
    FState := nil;

    FPrintCallback.Handler := nil;
    FPrintCallback.UserData := nil;
  end;
end;

constructor TDelphiC.Create();
begin
  inherited;
  FErrors := TList<TDCError>.Create();
  NewState();
end;

destructor TDelphiC.Destroy();
begin
  FreeState();
  FErrors.Free();

  inherited;
end;

class function   TDelphiC.GetVersionStr(): string;
begin
  Result := Format('%d.%d.%d', [DC_MAJOR_VERSION, DC_MINOR_VERSION, DC_PATCH_VERSION]);
end;

procedure TDelphiC.SetPrintCallback(const AUserData: Pointer; const AHandler: TDCPrintCallback);
begin
  FPrintCallback.Handler := AHandler;
  FPrintCallback.UserData := AUserData;
end;

procedure TDelphiC.Print(const AText: string; const AArgs: array of const);
var
  LText: string;
begin
  LText := Format(AText, AArgs);
  if Assigned(FPrintCallback.Handler) then
  begin
    FPrintCallback.Handler(LText, FPrintCallback.UserData);
  end;
end;

function TDelphiC.GetErrors(): TArray<TDCError>;
begin
  Result := FErrors.ToArray;
end;

procedure TDelphiC.ClearErrors();
begin
  FErrors.Clear;
end;

procedure TDelphiC.Reset();
begin
  FreeState();
  NewState();
end;

function TDelphiC.AddIncludePath(const APathName: string): Boolean;
begin
  // Allow in new or configured state, but not after compilation
  if FWorkflowState > wsConfigured then
  begin
    Result := False;
    Exit;
  end;

  Result := tcc_add_include_path(FState, AsUTF8(APathName)) >= 0;
end;

function TDelphiC.AddSystemIncludePath(const APathName: string): Boolean;
begin
  // Allow in new or configured state, but not after compilation
  if FWorkflowState > wsConfigured then
  begin
    Result := False;
    Exit;
  end;

  Result := tcc_add_sysinclude_path(FState, AsUTF8(APathName)) >= 0;
end;

function TDelphiC.AddLibraryPath(const APathName: string): Boolean;
begin
  // Allow in new or configured state, but not after compilation
  if FWorkflowState > wsConfigured then
  begin
    Result := False;
    Exit;
  end;

  Result := tcc_add_library_path(FState, AsUTF8(APathName)) >= 0;
end;

function TDelphiC.AddLibrary(const ALibraryName: string): Boolean;
begin
  // Allow in new or configured state, but not after compilation
  if FWorkflowState > wsConfigured then
  begin
    Result := False;
    Exit;
  end;

  Result := tcc_add_library(FState, AsUTF8(ALibraryName)) >= 0;
end;

function TDelphiC.DefineSymbol(const ASymbol, AValue: string): Boolean;
begin
  // Allow in new or configured state, but not after compilation
  if FWorkflowState > wsConfigured then
  begin
    Result := False;
    Exit;
  end;

  // tcc_define_symbol doesn't return error code, so assume success
  tcc_define_symbol(FState, AsUTF8(ASymbol), AsUTF8(AValue));
  Result := True;
end;

function TDelphiC.UndefineSymbol(const ASymbol: string): Boolean;
begin
  // Allow in new or configured state, but not after compilation
  if FWorkflowState > wsConfigured then
  begin
    Result := False;
    Exit;
  end;

  // tcc_undefine_symbol doesn't return error code, so assume success
  tcc_undefine_symbol(FState, AsUTF8(ASymbol));
  Result := True;
end;

function  TDelphiC.SetOuput(const AOutput: TDCOutput): Boolean;
begin
  // Only allow if we haven't started compilation yet
  if FWorkflowState <> wsNew then
  begin
    Result := False;
    Exit;
  end;

  Result := Boolean(tcc_set_output_type(FState, Ord(AOutput)) >= 0);

  if Result then
  begin
    FOutput := AOutput;
    FOutputSet := True;
    FWorkflowState := wsConfigured;
  end;
end;

function TDelphiC.SetOption(const AOption: string): Boolean;
var
  LOption: string;
begin
  Result := False;

  if not FOutputSet or (FWorkflowState > wsConfigured) then
    Exit;

  // Block bounds checking options - they crash on Win64
  LOption := AOption.Trim.ToLower;
  if (LOption = '-b') or LOption.StartsWith('-bt') then
  begin
    // Silently reject - these options cause crashes on Win64
    Exit;
  end;

  if tcc_set_options(FState, AsUTF8(AOption)) = 0 then
  begin
    Result := True;
  end;
end;

function TDelphiC.SetSubsystem(const ASubsystem: TDCSubsystem): Boolean;
const
  CSubsystemOptions: array[TDCSubsystem] of string = (
    '-Wl,-subsystem=console',
    '-Wl,-subsystem=gui'
  );
begin
  Result := False;

  // Subsystem only valid for PE executables/DLLs
  if not (FOutput in [opEXE, opDLL]) then
    Exit;

  Result := SetOption(CSubsystemOptions[ASubsystem]);
end;

function TDelphiC.SetDebugInfo(const AEnabled: Boolean): Boolean;
begin
  if AEnabled then
    Result := SetOption('-g')
  else
    Result := True; // No flag to disable, it's default off
end;

function TDelphiC.DisableWarnings(): Boolean;
begin
  Result := SetOption('-w');
end;

function TDelphiC.SetWarningsAsErrors(): Boolean;
begin
  Result := SetOption('-Werror');
end;

function TDelphiC.SetUnsignedChar(): Boolean;
begin
  Result := SetOption('-funsigned-char');
end;

function TDelphiC.SetSignedChar(): Boolean;
begin
  Result := SetOption('-fsigned-char');
end;


function TDelphiC.CompileString(const ACode, AFilename: string): Boolean;
var
  LCode: string;
begin
  // Must set output type first, and not be past compilation stage
  if not FOutputSet or (FWorkflowState > wsConfigured) then
  begin
    Result := False;
    Exit;
  end;

  LCode := '#line 1 "' + AFilename + '"' + #13#10 + ACode;
  Result := tcc_compile_string(FState, AsUTF8(LCode)) >= 0;
  if Result then
    FWorkflowState := wsCompiled;
end;

function TDelphiC.CompileFile(const AFilename: string): Boolean;
begin
  // Same implementation as AddFile, just clearer semantics
  Result := AddFile(AFilename);

  // Update workflow state if successful
  if Result and (FWorkflowState = wsConfigured) then
    FWorkflowState := wsCompiled;
end;

function TDelphiC.AddFile(const AFilename: string): Boolean;
begin
  // Must set output type first, and not be past compilation stage
  if not FOutputSet or (FWorkflowState > wsConfigured) then
  begin
    Result := False;
    Exit;
  end;

  Result := tcc_add_file(FState, AsUTF8(AFilename)) >= 0;
  if Result then
    FWorkflowState := wsCompiled;
end;

function TDelphiC.OutputFile(const AFilename: string): Boolean;
begin
  // Only allow for non-memory output, after compilation, NO relocation
  if (FOutput = opMemory) or (FWorkflowState <> wsCompiled) then
  begin
    Result := False;
    Exit;
  end;

  Result := tcc_output_file(FState, AsUTF8(AFilename)) >= 0;
  if Result then
    FWorkflowState := wsFinalized;
end;

function TDelphiC.Run(const AArgc: Integer; const AArgv: Pointer): Integer;
begin
  // Only allow for executable output, after compilation, NO relocation
  if (FOutput <> opExe) or (FWorkflowState <> wsCompiled) then
  begin
    Result := -1;
    Exit;
  end;

  Result := tcc_run(FState, AArgc, AArgv);
  if Result >= 0 then
    FWorkflowState := wsFinalized;
end;

function TDelphiC.Relocate: Boolean;
begin
  // Only allow for memory output, after compilation, before relocation
  if (FOutput <> opMemory) or (FWorkflowState <> wsCompiled) then
  begin
    Result := False;
    Exit;
  end;

  Result := Boolean(tcc_relocate(FState) >= 0);
  if Result then
    FWorkflowState := wsRelocated;
end;

function TDelphiC.AddSymbol(const AName: string; const AValue: Pointer): Boolean;
begin
  // Only allow after compilation, before relocation for memory output
  if (FWorkflowState <> wsCompiled) or
     ((FOutput = opMemory) and (FWorkflowState >= wsRelocated)) then
  begin
    Result := False;
    Exit;
  end;

  Result := tcc_add_symbol(FState, AsUTF8(AName), AValue) >= 0;
end;

function TDelphiC.GetSymbol(const AName: string): Pointer;
begin
  // Only allow after relocation for memory output
  if (FOutput <> opMemory) or (FWorkflowState <> wsRelocated) then
  begin
    Result := nil;
    Exit;
  end;

  Result := tcc_get_symbol(FState, AsUTF8(AName));
end;
{$ENDREGION}

{$REGION ' MEM DLL LOADER '}
type
  PIMAGE_NT_HEADERS      = ^IMAGE_NT_HEADERS;
  PIMAGE_FILE_HEADER     = ^IMAGE_FILE_HEADER;
  PIMAGE_OPTIONAL_HEADER = ^IMAGE_OPTIONAL_HEADER;
  PIMAGE_SECTION_HEADER  = ^IMAGE_SECTION_HEADER;
  PIMAGE_DATA_DIRECTORY  = ^IMAGE_DATA_DIRECTORY;

  TDWORDArray = array[0..9999999] of Cardinal;
  PDWORDArray = ^TDWORDArray;
  TWORDArray  = array[0..99999999] of WORD;
  PWORDArray  = ^TWORDArray;

  IMAGE_DOS_HEADER = packed record
    e_magic: WORD;
    e_cblp: WORD;
    e_cp: WORD;
    e_crlc: WORD;
    e_cparhdr: WORD;
    e_minalloc: WORD;
    e_maxalloc: WORD;
    e_ss: WORD;
    e_sp: WORD;
    e_csum: WORD;
    e_ip: WORD;
    e_cs: WORD;
    e_lfarlc: WORD;
    e_ovno: WORD;
    e_res: array[0..3] of WORD;
    e_oemid: WORD;
    e_oeminfo: WORD;
    e_res2: array[0..9] of WORD;
    e_lfanew: Cardinal;
  end;

  PIMAGE_DOS_HEADER = ^IMAGE_DOS_HEADER;

  IMAGE_BASE_RELOCATION = packed record
    VirtualAddress: Cardinal;
    SizeOfBlock: Cardinal;
  end;

  PIMAGE_BASE_RELOCATION = ^IMAGE_BASE_RELOCATION;
  PIMAGE_EXPORT_DIRECTORY = ^IMAGE_EXPORT_DIRECTORY;

  DLLMAIN  = function(hinstDLL: Pointer; fdwReason: Cardinal; lpvReserved: Pointer): Integer; stdcall;
  PDLLMAIN = ^DLLMAIN;

  TMemCpy  = procedure(ADestination: Pointer; ASource: Pointer; ACount: NativeUInt); cdecl;
  PMemCpy  = ^TMemCpy;
  TZeroMem = procedure(AWhat: Pointer; ACount: NativeUInt); stdcall; // Function pointer type for RtlZeroMemory

procedure Internal_CopyMemory(ADestination: Pointer; ASource: Pointer; ACount: NativeUInt);
var
  LMemCpy: TMemCpy;
begin
  LMemCpy := TMemCpy(GetProcAddress(GetModuleHandleA('ntdll.dll'), 'memcpy'));
  LMemCpy(ADestination, ASource, ACount);
end;

procedure Internal_ZeroMemory(AWhat: Pointer; ACount: NativeUInt);
var
  LZeroMem: TZeroMem;
begin
  LZeroMem := TZeroMem(GetProcAddress(GetModuleHandleA('kernel32.dll'), 'RtlZeroMemory'));
  LZeroMem(AWhat, ACount);
end;

function AddToPointer(ASource: Pointer; AValue: Cardinal) : Pointer;overload;
begin
  Result := Pointer(NativeUInt(ASource) + NativeUInt(AValue));
end;

function AddToPointer(ASource: Pointer; AValue: NativeUInt) : Pointer; overload;
begin
  Result := Pointer(NativeUInt(ASource) + AValue);
end;

function DecPointer(ASource: Pointer; AValue: Pointer) : NativeUInt;
begin
  Result := NativeUInt(ASource) - NativeUInt(AValue);
end;

function DecPointerInt(ASource: Pointer; AValue: NativeUInt) : NativeUInt;
begin
  Result := NativeUInt(ASource) - NativeUInt(AValue);
end;

function min(a: Integer; b: Integer): Integer;
begin
  if (a<b) then
    Result := a
  else
    Result := b;
end;

function Internal_Load(AData: Pointer) : Pointer;
var
  LPtr: Pointer;
  LImageNTHeaders: PIMAGE_NT_HEADERS;
  LSectionIndex: Integer;
  LImageBaseDelta: Size_t;
  LRelocationInfoSize: UInt;
  LImageBaseRelocations,
  LReloc: PIMAGE_BASE_RELOCATION;
  LImports,
  LImport: PIMAGE_IMPORT_DESCRIPTOR;
  LDllMain: DLLMAIN;
  LImageBase: Pointer;

  LImageSectionHeader: PIMAGE_SECTION_HEADER;
  LVirtualSectionSize: Integer;
  LRawSectionSize: Integer;
  LSectionBase: Pointer;

  LRelocCount: Integer;
  LRelocInfo: PWORD;
  LRelocIndex: Integer;

  LMagic: PNativeUInt;

  LLibName: LPSTR;
  LLib: HMODULE;
  LPRVAImport: PNativeUInt;
  LFunctionName: LPSTR;
begin
  LPtr := AData;

  LPtr := Pointer(Int64(LPtr) + Int64(PIMAGE_DOS_HEADER(LPtr).e_lfanew));
  LImageNTHeaders := PIMAGE_NT_HEADERS(LPtr);

  LImageBase := VirtualAlloc(nil, LImageNTHeaders^.OptionalHeader.SizeOfImage, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  Internal_CopyMemory(LImageBase, AData, LImageNTHeaders^.OptionalHeader.SizeOfHeaders);

  LPtr := AddToPointer(LPtr,sizeof(LImageNTHeaders.Signature) + sizeof(LImageNTHeaders.FileHeader) + LImageNTHeaders.FileHeader.SizeOfOptionalHeader);

  for LSectionIndex := 0 to LImageNTHeaders.FileHeader.NumberOfSections-1 do
  begin
    LImageSectionHeader := PIMAGE_SECTION_HEADER(AddToPointer(LPtr,LSectionIndex*sizeof(IMAGE_SECTION_HEADER)));

    LVirtualSectionSize := LImageSectionHeader.Misc.VirtualSize;
    LRawSectionSize := LImageSectionHeader.SizeOfRawData;

    LSectionBase := AddToPointer(LImageBase,LImageSectionHeader.VirtualAddress);

    Internal_ZeroMemory(LSectionBase, LVirtualSectionSize);

    Internal_CopyMemory(LSectionBase,
      AddToPointer(AData,LImageSectionHeader.PointerToRawData),
      min(LVirtualSectionSize, LRawSectionSize));
  end;

  LImageBaseDelta := DecPointerInt(LImageBase,LImageNTHeaders.OptionalHeader.ImageBase);

  LRelocationInfoSize := LImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].Size;
  LImageBaseRelocations := PIMAGE_BASE_RELOCATION(AddToPointer(LImageBase,
    LImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].VirtualAddress));

  LReloc := LImageBaseRelocations;

  while DecPointer(LReloc,LImageBaseRelocations) < LRelocationInfoSize do
  begin
    LRelocCount := (LReloc.SizeOfBlock - sizeof(IMAGE_BASE_RELOCATION)) Div sizeof(WORD);

    LRelocInfo := PWORD(AddToPointer(LReloc,sizeof(IMAGE_BASE_RELOCATION)));

    for LRelocIndex := 0 to LRelocCount-1 do
    begin
      if (LRelocInfo^ and $f000) <> 0 then
      begin
        LMagic := PNativeUInt(AddToPointer(LImageBase,LReloc.VirtualAddress+(LRelocInfo^ and $0fff)));
        LMagic^ := NativeUInt(LMagic^ + LImageBaseDelta);
      end;

      Inc(LRelocInfo);
    end;

    LReloc := PIMAGE_BASE_RELOCATION(LRelocInfo);
  end;

  LImports := PIMAGE_IMPORT_DESCRIPTOR(AddToPointer(LImageBase,
    LImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress));

  LImport := LImports;

  while 0 <> LImport.Name do
  begin
    LLibName := LPSTR(AddToPointer(LImageBase,LImport.Name));

    LLib := LoadLibraryA(LLibName);

    if 0 = LImport.TimeDateStamp then
      LPRVAImport := AddToPointer(LImageBase,LImport.FirstThunk)
    else
      LPRVAImport := AddToPointer(LImageBase,LImport.Characteristics);

    while LPRVAImport^ <> 0 do
    begin
      if (PDWORD(LPRVAImport)^ and IMAGE_ORDINAL_FLAG32) <> 0 then
      begin
        LFunctionName := LPSTR(PDWORD(LPRVAImport)^ and $ffff);
      end
      else
      begin
        LFunctionName := LPSTR(@PIMAGE_IMPORT_BY_NAME(AddToPointer(LImageBase, PUInt(LPRVAImport)^)).Name[0]);
      end;

      LPRVAImport^ := NativeUInt(GetProcAddress(LLib, LFunctionName));

      Inc(LPRVAImport);
    end;

    Inc(LImport);
  end;

  FlushInstructionCache(GetCurrentProcess(), LImageBase, LImageNTHeaders.OptionalHeader.SizeOfImage);

  if 0 <> LImageNTHeaders.OptionalHeader.AddressOfEntryPoint then
  begin
    LDllMain := DLLMAIN(AddToPointer(LImageBase,LImageNTHeaders.OptionalHeader.AddressOfEntryPoint));

    if nil <> @LDllMain then
    begin
      LDllMain(Pointer(LImageBase), DLL_PROCESS_ATTACH, nil);
      LDllMain(Pointer(LImageBase), DLL_THREAD_ATTACH, nil);
    end;
  end;

  Result := Pointer(LImageBase);
end;

function Internal_GetProcAddress(hModule: Pointer; lpProcName: PAnsiChar) : Pointer;
var
  LImageNTHeaders: PIMAGE_NT_HEADERS;
  LExports: PIMAGE_EXPORT_DIRECTORY;
  LExportedSymbolIndex: Cardinal;
  LPtr: Pointer;
  LVirtualAddressOfName: Cardinal;
  LName: PAnsiChar;
  LIndex: WORD;
  LVirtualAddressOfAddressOfProc: Cardinal;
begin
  Result := nil;

  if nil <> hModule then
  begin
    LPtr := hModule;

    LPtr := Pointer(Int64(LPtr) + Int64(PIMAGE_DOS_HEADER(LPtr).e_lfanew));
    LImageNTHeaders := PIMAGE_NT_HEADERS(LPtr);

    LExports := PIMAGE_EXPORT_DIRECTORY(AddToPointer(hModule,
      LImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress));

    for LExportedSymbolIndex := 0 to LExports.NumberOfNames-1 do
    begin
      LVirtualAddressOfName := PDWORDArray(AddToPointer(hModule,LExports.AddressOfNames))[LExportedSymbolIndex];

      LName := LPSTR(AddToPointer(hModule,LVirtualAddressOfName));

      if lstrcmpA(LName, lpProcName) = 0 then
      begin
        LIndex := PWORDArray(AddToPointer(hModule,LExports.AddressOfNameOrdinals))[LExportedSymbolIndex];

        LVirtualAddressOfAddressOfProc := PDWORDArray(AddToPointer(hModule,LExports.AddressOfFunctions))[LIndex];

        Result := AddToPointer(hModule,LVirtualAddressOfAddressOfProc);
        Exit;
      end;
    end;
  end;
end;

procedure Internal_Unload(hModule: Pointer);
var
  LImageBase: Pointer;
  LPtr: Pointer;
  LImageNTHeaders: PIMAGE_NT_HEADERS;
  LDllMain: DLLMAIN;
begin
  if nil <> hModule then
  begin
    LImageBase := hModule;

    LPtr := Pointer(hModule);

    LPtr := Pointer(Int64(LPtr) + Int64(PIMAGE_DOS_HEADER(LPtr).e_lfanew));
    LImageNTHeaders := PIMAGE_NT_HEADERS(LPtr);

    LDllMain := DLLMAIN(AddToPointer(LImageBase,LImageNTHeaders.OptionalHeader.AddressOfEntryPoint));

    if nil <> @LDllMain then
    begin
      LDllMain(LImageBase, DLL_THREAD_DETACH, nil);
      LDllMain(LImageBase, DLL_PROCESS_DETACH, nil);
    end;
    VirtualFree(hModule, 0, MEM_RELEASE);
  end;
end;
{$ENDREGION}

{$REGION ' LOAD MEMORY DLL '}

{$R DelphiC.res}
var
  LMemDLLHandle: Pointer = nil;

function LoadMemDLL(out AError: string): Boolean;
var
  LResStream: TResourceStream;

  function f1d375d775e14a91acf50bc7b8e72c09(): string;
  const
    CValue = '46ca7568de29422d9d426891b4a15374';
  begin
    Result := CValue;
  end;

  procedure SetError(const AText: string; const AArgs: array of const);
  begin
    AError := Format(AText, AArgs);
  end;

begin
  Result := False;
  AError := '';

  // Load Memory DLL
  if Assigned(LMemDLLHandle) then Exit;
  try
    if not Boolean((FindResource(HInstance, PWideChar(f1d375d775e14a91acf50bc7b8e72c09()), RT_RCDATA) <> 0)) then
    begin
      SetError('Failed to find Memory DLL resource', []);
      Exit;
    end;

    LResStream := TResourceStream.Create(HInstance, f1d375d775e14a91acf50bc7b8e72c09(), RT_RCDATA);
    try
      LMemDLLHandle := Internal_Load(LResStream.Memory);

      if not Assigned(LMemDLLHandle) then
      begin
        SetError('Failed to load extracted Memory DLL', []);
        Exit;
      end;

      Result := True;
    finally
      LResStream.Free();
    end;

  except
    on E: Exception do
      SetError('Unexpected error: %s', [E.Message]);
  end;
end;

procedure UnloadMemDLL();
begin
  // Unload Memory DLL
  if Assigned(LMemDLLHandle) then
  begin
    Internal_Unload(LMemDLLHandle);
    LMemDLLHandle := nil;
  end;
end;

{$ENDREGION}

{$REGION ' LOAD TCC DLL '}


var
  LTCCDllHandle: THandle = 0;

function LoadTCCDLL(out AError: string): Boolean;
begin
  Result := False;
  if LTCCDllHandle <> 0 then Exit(True);

  LTCCDllHandle := LoadLibrary('tcc.dll');
  if LTCCDllHandle = 0 then
  begin
    AError := 'Failed to load TCC DLL';
    Exit;
  end;

  tcc_set_realloc := GetProcAddress(LTCCDllHandle, 'tcc_set_realloc');
  tcc_new := GetProcAddress(LTCCDllHandle, 'tcc_new');
  tcc_delete := GetProcAddress(LTCCDllHandle, 'tcc_delete');
  tcc_set_lib_path := GetProcAddress(LTCCDllHandle, 'tcc_set_lib_path');
  tcc_set_error_func := GetProcAddress(LTCCDllHandle, 'tcc_set_error_func');
  tcc_set_options := GetProcAddress(LTCCDllHandle, 'tcc_set_options');
  tcc_add_include_path := GetProcAddress(LTCCDllHandle, 'tcc_add_include_path');
  tcc_add_sysinclude_path := GetProcAddress(LTCCDllHandle, 'tcc_add_sysinclude_path');
  tcc_define_symbol := GetProcAddress(LTCCDllHandle, 'tcc_define_symbol');
  tcc_undefine_symbol := GetProcAddress(LTCCDllHandle, 'tcc_undefine_symbol');
  tcc_add_file := GetProcAddress(LTCCDllHandle, 'tcc_add_file');
  tcc_compile_string := GetProcAddress(LTCCDllHandle, 'tcc_compile_string');
  tcc_set_output_type := GetProcAddress(LTCCDllHandle, 'tcc_set_output_type');
  tcc_add_library_path := GetProcAddress(LTCCDllHandle, 'tcc_add_library_path');
  tcc_add_library := GetProcAddress(LTCCDllHandle, 'tcc_add_library');
  tcc_add_symbol := GetProcAddress(LTCCDllHandle, 'tcc_add_symbol');
  tcc_output_file := GetProcAddress(LTCCDllHandle, 'tcc_output_file');
  tcc_run := GetProcAddress(LTCCDllHandle, 'tcc_run');
  tcc_relocate := GetProcAddress(LTCCDllHandle, 'tcc_relocate');
  tcc_get_symbol := GetProcAddress(LTCCDllHandle, 'tcc_get_symbol');
  tcc_list_symbols := GetProcAddress(LTCCDllHandle, 'tcc_list_symbols');
  tcc_set_backtrace_func := GetProcAddress(LTCCDllHandle, 'tcc_set_backtrace_func');

  Result := True;
end;

procedure UnloadTCCDLL();
begin
  if LTCCDllHandle = 0 then Exit;
  FreeLibrary(LTCCDllHandle);
  LTCCDllHandle := 0;
end;

{$ENDREGION}

{$REGION ' UNIT INIT '}

procedure ShowError(const AError: string);
begin
  MessageBox(0, PWideChar(AError), 'Fatal Error', MB_ICONERROR);
end;

procedure Load();
var
  LError: string;
begin
  if not LoadMemDLL(LError) then
  begin
    ShowError(LError);
    Exit;
  end;

  if not LoadTCCDLL(LError) then
  begin
    ShowError(LError);
    Exit;
  end;
end;

procedure Unload();
begin
  UnloadTCCDLL();
  UnloadMemDLL();
end;

initialization
begin
  ReportMemoryLeaksOnShutdown := True;
  SetExceptionMask(GetExceptionMask + [exOverflow, exInvalidOp]);
  SetConsoleCP(CP_UTF8);
  SetConsoleOutputCP(CP_UTF8);
  Load();
end;

finalization
begin
  Unload();
end;

{$ENDREGION}

end.
