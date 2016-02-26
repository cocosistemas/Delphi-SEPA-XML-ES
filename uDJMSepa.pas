unit uDJMSepa;
{
https://github.com/cocosistemas/Delphi-SEPA-XML-ES
Diego J.Muñoz. Freelance. Cocosistemas.com
}

interface

function uSEPA_CleanStr(sIn:string; iMaxLen : Integer = -1):string;

function uSEPA_GenerateUUID: String;

function uSEPA_FormatDateTimeXML(const d: TDateTime): String;

function uSEPA_FormatAmountXML(const d: Currency; const digits: Integer = 2): String;

function uSEPA_FormatDateXML(const d: TDateTime): String;

procedure uSEPA_writeAccountIdentification(var fTxt:TextFile; sIBAN:string);
procedure uSEPA_writeBICInfo(var fTxt:TextFile; sBIC:string);

implementation
uses SysUtils, Math;

function uSEPA_FormatDateXML(const d: TDateTime): String;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd', d);
end;

function uSEPA_FormatAmountXML(const d: Currency; const digits: Integer = 2): String;
var
  OldDecimalSeparator: Char;
  {$if CompilerVersion>22}  //superiores a xe
  FS: TFormatSettings;
  {$ifend}
begin
  {$if CompilerVersion>22}
    OldDecimalSeparator := FS.DecimalSeparator;
    FS.DecimalSeparator := '.';
  {$else}
    OldDecimalSeparator := DecimalSeparator;
    DecimalSeparator := '.';
  {$ifend}
  Result := CurrToStrF(d, ffFixed, digits);
  {$if CompilerVersion>22}
    FS.DecimalSeparator := OldDecimalSeparator;
  {$else}
    DecimalSeparator := OldDecimalSeparator;
  {$ifend}
end;

function uSEPA_FormatDateTimeXML(const d: TDateTime): String;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"', d);
end;

function uSEPA_GenerateUUID: String;
var
  uid: TGuid;
  res: HResult;
begin
  res := CreateGuid(Uid);
  if res = S_OK then
  begin
    Result := GuidToString(uid);
    Result := StringReplace(Result, '-', '', [rfReplaceAll]);
    Result := StringReplace(Result, '{', '', [rfReplaceAll]);
    Result := StringReplace(Result, '}', '', [rfReplaceAll]);
  end
  else
    Result := IntToStr(RandomRange(10000, High(Integer)));  // fallback to simple random number
end;

function uSEPA_CleanStr(sIn:string; iMaxLen : Integer = -1):string;
var
i    : integer;
sOut : string;
begin
sOut:=sIn;
sOut := StringReplace(sOut,'á','a',[rfReplaceAll]);
sOut := StringReplace(sOut,'Á','A',[rfReplaceAll]);
sOut := StringReplace(sOut,'é','e',[rfReplaceAll]);
sOut := StringReplace(sOut,'É','E',[rfReplaceAll]);
sOut := StringReplace(sOut,'í','i',[rfReplaceAll]);
sOut := StringReplace(sOut,'Í','I',[rfReplaceAll]);
sOut := StringReplace(sOut,'ó','o',[rfReplaceAll]);
sOut := StringReplace(sOut,'Ó','O',[rfReplaceAll]);
sOut := StringReplace(sOut,'ú','u',[rfReplaceAll]);
sOut := StringReplace(sOut,'Ú','U',[rfReplaceAll]);
sOut := StringReplace(sOut,'Á','A',[rfReplaceAll]);
sOut := StringReplace(sOut,'é','e',[rfReplaceAll]);
sOut := StringReplace(sOut,'É','E',[rfReplaceAll]);
sOut := StringReplace(sOut,'í','i',[rfReplaceAll]);
sOut := StringReplace(sOut,'Í','I',[rfReplaceAll]);
sOut := StringReplace(sOut,'ó','o',[rfReplaceAll]);
sOut := StringReplace(sOut,'Ó','O',[rfReplaceAll]);
sOut := StringReplace(sOut,'ú','u',[rfReplaceAll]);
sOut := StringReplace(sOut,'Ú','U',[rfReplaceAll]);
sOut := StringReplace(sOut,'Ö','O',[rfReplaceAll]);
sOut := StringReplace(sOut,'ö','o',[rfReplaceAll]);
sOut := StringReplace(sOut,'Ñ','N',[rfReplaceAll]);
sOut := StringReplace(sOut,'ñ','n',[rfReplaceAll]);
sOut := StringReplace(sOut,'Ç','C',[rfReplaceAll]);
sOut := StringReplace(sOut,'ç','c',[rfReplaceAll]);

// Recorrer el sOut para eliminar los caracteres no permitidos
for i := 1 to Length(sOut)
do begin
   if not(Ord(sOut[i]) in [65..90,97..122,48..57,47,45,63,58,40,41,46,44,39,43,32])
   then sOut[i] := ' ';
   end;
// Convertir a mayúsculas
//sOut := ansiuppercase(sOut);

// Codificar a Utf8
sOut := Utf8Encode(Trim(sOut));
if (iMaxLen >= 0) and (Length(sOut) > iMaxLen)
then sOut := Copy(sOut, 1, iMaxLen);
Result:=sOut;
end;

procedure uSEPA_writeAccountIdentification;
begin
WriteLn(FTxt, '<Id><IBAN>'+uSEPA_CleanStr(sIBAN)+'</IBAN></Id>');
end;

procedure uSEPA_writeBICInfo;
begin
 {if (BIC = '') and (OthrID <> '') then
    WriteLn(FsTxt, '<FinInstnId><Othr><Id>'+uSEPA_CleanString(OthrID)+'</Id></Othr></FinInstnId>')
  else}
    WriteLn(FTxt, '<FinInstnId><BIC>'+uSEPA_CleanStr(sBIC)+'</BIC></FinInstnId>');
end;


end.
