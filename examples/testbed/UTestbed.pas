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

unit UTestbed;

interface

procedure RunTests();

implementation

uses
  System.SysUtils,
  System.TypInfo,
  DelphiC;

procedure Pause();
begin
  WriteLn;
  Write('Press ENTER to continue...');
  ReadLn;
  WriteLn;
end;

procedure Test01();
type
  TAddFunc = function(AInt1, AInt2: Integer): Integer; cdecl;
const
  // Intentionally broken: "int1" instead of "int"
  CCode = 'int add(int1 a, int b) { return a + b; }';
var
  LDC: TDelphiC;
  LAddFunc: TAddFunc;
  LErrors: TArray<TDCError>;
  LError: TDCError;
begin
  WriteLn('=== Test01: Error Handling ===');
  LDC := TDelphiC.Create();
  try
    LDC.SetPrintCallback(
      nil,
      procedure (const AText: string; const AUserData: Pointer)
      begin
        WriteLn('[TCC] ', AText);
      end
    );

    LDC.SetOuput(opMemory);

    WriteLn('Compiling code with intentional error...');
    if not LDC.CompileString(CCode) then
    begin
      WriteLn('Compilation failed (as expected)');
      WriteLn;
      LErrors := LDC.GetErrors();
      WriteLn('Captured ', Length(LErrors), ' error(s):');
      for LError in LErrors do
      begin
        WriteLn('  File: ', LError.Filename);
        WriteLn('  Line: ', LError.Line);
        WriteLn('  Type: ', GetEnumName(TypeInfo(TDCErrorType), Ord(LError.ErrorType)));
        WriteLn('  Msg:  ', LError.Message);
        WriteLn;
      end;
    end
    else
    begin
      WriteLn('ERROR: Compilation should have failed!');
      if LDC.Relocate() then
      begin
        LAddFunc := LDC.GetSymbol('add');
        if Assigned(LAddFunc) then
          WriteLn('Result: ', LAddFunc(10, 20));
      end;
    end;
  finally
    LDC.Free();
  end;
end;

procedure Test02();
type
  TAddFunc = function(AInt1, AInt2: Integer): Integer; cdecl;
const
  CCode = 'int add(int a, int b) { return a + b; }';
var
  LDC: TDelphiC;
  LAddFunc: TAddFunc;
begin
  WriteLn('=== Test02: Successful Compilation ===');
  LDC := TDelphiC.Create();
  try
    LDC.SetPrintCallback(
      nil,
      procedure (const AText: string; const AUserData: Pointer)
      begin
        WriteLn('[TCC] ', AText);
      end
    );

    if not LDC.SetOuput(opMemory) then
    begin
      WriteLn('Failed to set output mode');
      Exit;
    end;

    WriteLn('Compiling...');
    if not LDC.CompileString(CCode) then
    begin
      WriteLn('Compilation failed');
      Exit;
    end;

    WriteLn('Relocating...');
    if not LDC.Relocate() then
    begin
      WriteLn('Relocation failed');
      Exit;
    end;

    WriteLn('Getting symbol...');
    LAddFunc := LDC.GetSymbol('add');
    if Assigned(LAddFunc) then
    begin
      WriteLn('SUCCESS: add(10, 20) = ', LAddFunc(10, 20));
    end
    else
    begin
      WriteLn('Failed to retrieve symbol "add"');
    end;
  finally
    LDC.Free();
  end;
end;

procedure RunTests();
var
  LNum: Integer;
begin
  try
    WriteLn('DelphiC™ v' + TDelphiC.GetVersionStr());
    WriteLn('===============');
    WriteLn;

    LNum := 02;

    case LNum of
      01: Test01();
      02: Test02();
    end;

  except
    on E: Exception do
    begin
      WriteLn(Format('Fatal Error: %s', [E.Message]));
    end;
  end;

  Pause();

end;

end.
