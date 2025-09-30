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
   * tinycc - https://github.com/TinyCC/tinycc

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

procedure ShowErrors(const ACompiler: TDelphiC);
var
  LErrors: TArray<TDCError>;
  LError: TDCError;
begin
  WriteLn;
  LErrors := ACompiler.GetErrors();
  if Length(LErrors) = 0 then Exit;

  WriteLn('Captured ', Length(LErrors), ' error(s):');
  for LError in LErrors do
  begin
    WriteLn('  File: ', LError.Filename);
    WriteLn('  Line: ', LError.Line);
    WriteLn('  Type: ', GetEnumName(TypeInfo(TDCErrorType), Ord(LError.ErrorType)));
    WriteLn('  Msg:  ', LError.Message);
    WriteLn;
  end;
end;

procedure Test01();
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
    ShowErrors(LDC);
    LDC.Free();
  end;
end;

procedure Test02;
const
  CAddCode = 'int add(int a, int b) { return a + b; }';
  CMainCode = '#include <stdio.h>' + sLineBreak +
              'int add(int, int);' + sLineBreak +
              'int main() {' + sLineBreak +
              '  int result = add(2, 3);' + sLineBreak +
              '  printf("Result: %d\n", result);' + sLineBreak +
              '  return 0;' + sLineBreak +
              '}';
var
  LCompiler: TDelphiC;

begin
  WriteLn('=== Test02: Compile and Link to EXE ===');
  LCompiler := TDelphiC.Create();
  try
    LCompiler.SetPrintCallback(
      nil,
      procedure (const AText: string; const AUserData: Pointer)
      begin
        WriteLn('[TCC] ', AText);
      end
    );

    // Compile unit1 to object file
    WriteLn('Setting output mode to OBJ...');
    if not LCompiler.SetOuput(opOBJ) then
    begin
      WriteLn('Failed to set output mode to OBJ');
      Exit;
    end;

    WriteLn('Compiling add function to object file...');
    if not LCompiler.CompileString(CAddCode) then
    begin
      WriteLn('Failed to compile add function');
      Exit;
    end;

    WriteLn('Outputting unit1.o...');
    if not LCompiler.OutputFile('unit1.o') then
    begin
      WriteLn('Failed to output unit1.o');
      Exit;
    end;

    // Reset and link everything
    WriteLn('Resetting compiler...');
    LCompiler.Reset();

    WriteLn('Setting output mode to EXE...');
    if not LCompiler.SetOuput(opEXE) then
    begin
      WriteLn('Failed to set output mode to EXE');
      Exit;
    end;

    WriteLn('Adding unit1.o...');
    if not LCompiler.AddFile('unit1.o') then
    begin
      WriteLn('Failed to add unit1.o');
      Exit;
    end;

    WriteLn('Compiling main program...');
    if not LCompiler.CompileString(CMainCode) then
    begin
      WriteLn('Failed to compile main program');
      Exit;
    end;

    WriteLn('Outputting program.exe...');
    if not LCompiler.OutputFile('program.exe') then
    begin
      WriteLn('Failed to output program.exe');
      Exit;
    end;

    WriteLn('SUCCESS: program.exe created');
  finally
    ShowErrors(LCompiler);
    LCompiler.Free();
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
