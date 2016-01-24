unit uDJMSepa3414XML;
{
https://github.com/cocosistemas/Delphi-SEPA-XML-ES
Diego J.Muñoz. Freelance. Cocosistemas.com
}
//2016-01-20
//ver los pdfs de los bancos, con la norma.
//34.14 pagos. 'Sepa credit transfer'

//el ORDENANTE le paga al BENEFICIARIO

//Tenemos un array de Ordenantes (**cada uno con un IBAN de cargo**), y para cada Ordenante
//un array con sus ordenes de pago
{
uso:
setInfoPresentador
- Añadimos Ordenante: addOrdenante (uno por cada cuenta de cargo del pago, donde nos cargan lo pagado)
- Añadimos los pagos: addPago (uno por cada pago, el solo se coloca en su Ordenante, éste ha tenido que
ser añadido previamente)
- createfile (las ordenes estan en los arrays)
- closefile
}

interface

type
//info de una orden de pago (norma 34.14 xml)
TInfoPago = class
           sIdPago: string; //id unico pago, ejemplo:20130930Fra.509301
           mImporte: Double;
           sBICBeneficiario:string;
           sNombreBeneficiario:string;
           sIBANBeneficiario:string;
           sConcepto:string;
end;

TListOfPagos = array[1..5000] of TInfoPago;

//un conjunto de pagos por Ordenante, lo utilizamos por si utilizan
//pagos a cargar en diferentes cuentas (el <PmtInf> contiene la info del Ordenante, con su cuenta; y los
//pagos relacionados con este Ordenante/cuenta de cargo
TInfoOrdenante = class
                sPayMentId:string; //Ejemplo: 2013-10-28_095831Remesa 218 UNICO POR Ordenante
                mSumaImportes:Double;
                sNombreOrdenante:string;
                sIBANOrdenante:string;
                sBICOrdenante:string;
                listPagos : TListOfPagos;
                iPagos : Integer;
end;

TListOrdenantes = array[1..10] of TInfoOrdenante;

TDJMNorma3414XML = class //el Ordenante paga al Beneficiario
   FsFileName : string;
   FsTxt : text;
   FiOrdenantes : integer;
   FListOrdenantes : TListOrdenantes; //Ordenantes, uno por cada cuenta de cargo

   FdFileDate : TDateTime;   //fecha del fichero
   FmTotalImportes : double;  //suma de los importes de los pagos
   FsNombrePresentador : string; //nombre del presentador (el 'initiator')
   FsIdPresentador : string; //id presentador norma AT02
   FdOrdenesPago  : TDateTime; //fecha del cargo en cuenta, PARA TODAS LAS ORDENES

   private
   procedure WriteGroupHeader;
   procedure writeOrdenesPago(oOrdenante:TInfoOrdenante);
   procedure writeCreditTransferOperationInfo(oPago:TInfoPago);

   function CalculateNumOperaciones:Integer;

   public
   constructor create;
   destructor destroy; reintroduce;

   procedure SetInfoPresentador(dFileDate:TDateTime;sNombrePresentador:string;
                         sIdPresentador:string;
                         dOrdenesPago:TDateTime);

   procedure AddOrdenante(
                         sPayMentId:string;
                         sNombreOrdenante:string;
                         sIBANOrdenante:string;
                         sBICOrdenante:string
                        );

   procedure AddPago(
                     sIdPago: string; //id unico pago, ejemplo:20130930Fra.509301
                     mImporte: Double;
                     sBICBeneficiario:string;
                     sNombreBeneficiario:string;
                     sIBANBeneficiario:string;
                     sConcepto:string;
                     sIBANOrdenante:string //el pago lo colocamos en la info de su Ordenante, por la cuenta
                     );
   procedure CreateFile(sFileName:string);
   procedure closeFile;
   function HayPagos:Boolean;

end;

implementation
uses uDJMSepa, SysUtils, windows, math, dialogs;

const
 C_Schema_34 = 'pain.001.001.03';
 C_INITIATOR_NAME_MAX_LENGTH = 70;
 C_BENEFICIARIO_NAME_MAX_LEN = 70;
 C_Ordenante_NAME_MAXLEN = 70;
 C_RMTINF_MAXLEN = 140;
 C_MNDTID_MAXLEN = 35;

constructor TDJMNorma3414XML.Create;
begin
  FiOrdenantes:=0;
  FdFileDate:=Now;
  FmTotalImportes:=0;
  FsNombrePresentador:='';
  FsIdPresentador:='';
  FdOrdenesPago:=Now;
end;

procedure TDJMNorma3414XML.SetInfoPresentador;
begin
  FdFileDate:=dFileDate;
  FsNombrePresentador:=sNombrePresentador;
  FsIdPresentador:=sIdPresentador;
  FdOrdenesPago:=dOrdenesPago;
end;

destructor TDJMNorma3414XML.destroy;
var
  i,j:Integer;
begin
for i:=1 to FiOrdenantes
do begin
   //para cada Ordenante destruimos sus pagos
   for j:= 1 to FlistOrdenantes[i].iPagos
   do begin
      FListOrdenantes[i].listPagos[j].free;
      end;
   FListOrdenantes[i].free;
   end;
inherited destroy;
end;

procedure TDJMNorma3414XML.WriteGroupHeader;
begin
  //1.0 Group Header Conjunto de características compartidas por todas las operaciones incluidas en el mensaje
  Writeln(FsTxt, '<GrpHdr>');

  //1.1 MessageId Referencia asignada por la parte iniciadora y enviada a la siguiente
  //parte de la cadena para identificar el mensaje de forma inequívoca
  Writeln(FsTxt, '<MsgId>'+uSEPA_CleanStr(uSEPA_GenerateUUID)+'</MsgId>');

  //1.2 Fecha y hora cuando la parte iniciadora ha creado un (grupo de) instrucciones de pago
  //(con 'now' es suficiente)
  Writeln(FsTxt, '<CreDtTm>'+uSEPA_FormatDateTimeXML(FdFileDate)+'</CreDtTm>');

  //1.6  Número de operaciones individuales que contiene el mensaje
  Writeln(FsTxt, '<NbOfTxs>'+IntToStr(CalculateNumOperaciones)+'</NbOfTxs>');

  //1.7 Suma total de todos los importes individuales incluidos en el mensaje
  writeLn(FsTxt, '<CtrlSum>'+uSEPA_FormatAmountXML(FmTotalImportes)+'</CtrlSum>');

  //1.8 Parte que presenta el mensaje. En el mensaje de presentación, puede ser el “Ordenante” o “el presentador”
  Write(FsTxt, '<InitgPty>');
      //Nombre de la parte
      WriteLn(FsTxt, '<Nm>'+uSEPA_CleanStr(FsNombrePresentador, C_INITIATOR_NAME_MAX_LENGTH)+'</Nm>');

      //Para el sistema de adeudos SEPA se utilizará exclusivamente la etiqueta “Otra” estructurada
      //según lo definido en el epígrafe “Identificador del presentador” de la sección 3.3
      WriteLn(FsTxt, '<Id>');
      WriteLn(FsTxt, '<OrgId>');
      WriteLn(FsTxt, '<Othr>');
      WriteLn(FsTxt, '<Id>'+FsIdPresentador+'</Id>');
      WriteLn(FsTxt, '</Othr>');
      WriteLn(FsTxt, '</OrgId>');
      WriteLn(FsTxt, '</Id>');
  Writeln(FsTxt,'</InitgPty>');

  Writeln(FsTxt, '</GrpHdr>');
end;


procedure TDJMNorma3414XML.CreateFile;
var
  iOrdenante:Integer;
begin
FsFileName:=sFileName;
assignFile(FsTxt,sFileName);
rewrite(FsTxt);
WriteLn(FsTxt, '<?xml version="1.0" encoding="UTF-8"?>');

WriteLn(FsTxt,
'<Document xmlns="urn:iso:std:iso:20022:tech:xsd:'+C_Schema_34+'"'+
                  ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');

//MESSAGE ROOT. Identifica el tipo de mensaje: iniciación de adeudos directos
WriteLn(FsTxt, '<CstmrDrctDbtInitn>');
writeGroupHeader;
//la info de cada Ordenante 
for iOrdenante:=1 to FiOrdenantes
do begin
   if FListOrdenantes[iOrdenante].iPagos>0
   then writeOrdenesPago(FListOrdenantes[iOrdenante]);
   end;
WriteLn(FsTxt, '</CstmrDrctDbtInitn>');
WriteLn(FsTxt, '</Document>');
end;

procedure TDJMNorma3414XML.closeFile;
begin
  close(FsTxt);
end;

procedure TDJMNorma3414XML.writeOrdenesPago;
var
  iPago:Integer;
begin
   //2.0 Información del pago - PaymentInformation
  writeLn(FsTxt, '<PmtInf>');
  //2.1 Identificación de Información del pago - PaymentInformationIdentification
  //Referencia asignada por el ordenante para identificar claramente el bloque de información de pago dentro del mensaje
  writeLn(FsTxt, '<PmtInfId>'+uSEPA_CleanStr(oOrdenante.sPaymentId)+'</PmtInfId>');
  //2.2 Método de pago - PaymentMethod
  writeLn(FsTxt, '<PmtMtd>'+'TRF'+'</PmtMtd>');
  //2.4 Número de operaciones - NumberOfTransactions 
  writeLn(FsTxt, '<NbOfTxs>'+IntToStr(oOrdenante.iPagos)+'</NbOfTxs>');
  //2.5 Con trol de suma - ControlSum
  //Suma total de todos los importes individuales incluidos en el bloque de información
  //de pago, sin tener en cuenta las divisas. Sirve como elemento de control.  
  writeLn(FsTxt, '<CtrlSum>'+uSEPA_FormatAmountXML(oOrdenante.mSumaImportes)+'</CtrlSum>');
  //2.6 Información del tipo de pago - PaymentTypeInformation  
  writeLn(FsTxt, '<PmtTpInf>');
  //2.8 Nivel de servicio - ServiceLevel
  writeLn(FsTxt, '<SvcLvl><Cd>'+'SEPA'+'</Cd></SvcLvl>');
  writeLn(FsTxt, '</PmtTpInf>');
  //2.17 Fecha de ejecución solicitada - Requested ExecutionDate
  writeLn(FsTxt, '<ReqdExctnDt>'+uSEPA_FormatDateXML(FdOrdenesPago)+'</ReqdExctnDt>');
  //2.19 Ordenante - Debtor
  writeLn(FsTxt, '<Dbtr><Nm>'+uSEPA_CleanStr(oOrdenante.sNombreOrdenante)+'</Nm></Dbtr>');

  //2.20 Cuenta del ordenante - DebtorAccount  
  writeLn(FsTxt, '<DbtrAcct>');
  uSEPA_writeAccountIdentification(FsTxt, oOrdenante.sIBANOrdenante);
  writeLn(FsTxt, '</DbtrAcct>');
  
  //2.21 Entidad del ordenante - DebtorAgent
  writeLn(FsTxt, '<DbtrAgt>');
  uSEPA_writeBICInfo(FsTxt, oOrdenante.sBICOrdenante);
  writeLn(FsTxt, '</DbtrAgt>');

  //2.24 Cláusula de gastos - ChargeBearer
  //writeLn(FsTxt, '<ChrgBr>'+uSEPA_CleanString(ChrgBr)+'</ChrgBr>');

  for iPago := 1 to oOrdenante.iPagos
  do begin
     writeCreditTransferOperationInfo(oOrdenante.ListPagos[iPago]);
     end;

  writeLn(FsTxt, '</PmtInf>');
end;

procedure TDJMNorma3414XML.writeCreditTransferOperationInfo;
begin
  //2.27 Información de tran sferencia individual - CreditTransferTran sactionInformation
  WriteLn(FsTxt, '<CdtTrfTxInf>');

  //2.28 Identificación del pago - PaymentIdentification
  Write(FsTxt, '<PmtId>');
  //2.30 Identificación de extremo a extremo - EndTo EndIdentification
  //Referencia única que asigna la parte i niciadora para identi ficar la operación
  //y que se transmite sin cambios a lo largo de la cadena del pago hasta el beneficiario.
  Write(FsTxt,'<EndToEndId>'+uSEPA_CleanStr(oPago.sIdPago)+'</EndToEndId>');
  WriteLn(FsTxt,'</PmtId>');

  //2.31 Información del tipo de pago – PaymentTypeInformation
  //<PmtTpInf>

  //2.42 Importe - Amoun t
  WriteLn(FsTxt, '<Amt><InstdAmt Ccy="'+'EUR'+'">'+uSEPA_FormatAmountXML(oPAgo.mImporte)+'</InstdAmt></Amt>');

  //2.77 Entidad del beneficiario - CreditorAgent 
  WriteLn(FsTxt, '<CdtrAgt>');
  uSEPA_writeBICInfo(FsTxt, oPago.sBICBeneficiario);
  WriteLn(FsTxt, '</CdtrAgt>');

  //2.79 Beneficiario - Creditor
  WriteLn(FsTxt, '<Cdtr><Nm>'+uSEPA_CleanStr(oPago.sNombreBeneficiario, C_BENEFICIARIO_NAME_MAX_LEN)+'</Nm></Cdtr>');

  //2.80 Cuenta del beneficiario - CreditorAccount
  WriteLn(FsTxt, '<CdtrAcct>');
  uSEPA_writeAccountIdentification(FsTxt, oPago.sIBANBeneficiario);
  WriteLn(FsTxt, '</CdtrAcct>');

  //2.98 Concepto - RemittanceInformation
  WriteLn(FsTxt, '<RmtInf><Ustrd>'+uSEPA_CleanStr(oPago.sConcepto, C_RMTINF_MAXLEN)+'</Ustrd></RmtInf>');

  WriteLn(FsTxt, '</CdtTrfTxInf>');
end;

procedure TDJMNorma3414XML.addPago;
var
  iOrdenanteFound:Integer;
  iOrdenanteAux:Integer;
  iPagosAux:Integer;
begin
//localizar en el arry de Ordenantes el iban, añadirlo en los pagos de ese Ordenante
iOrdenanteFound:=-1;
for iOrdenanteAux:=1 to FiOrdenantes
do begin
   if FListOrdenantes[iOrdenanteAux].sIBANOrdenante = sIBANOrdenante
   then begin
        iOrdenanteFound:=iOrdenanteAux;
        end;
   end;
if iOrdenanteFound=-1
then begin
     ShowMessage('No se encontró Ordenante para el IBAN: '+sIBANOrdenante);
     Exit;
     end;

if FListOrdenantes[iOrdenanteFound].iPagos=5000
then begin
     showmessage('No admitimos más de 5000 pagos por Ordenante');
     Exit;
     end;

//hemos encontrado el Ordenante con ese IBAN, añadimos un pago
FListOrdenantes[iOrdenanteFound].iPagos:=FListOrdenantes[iOrdenanteFound].iPagos+1;
iPagosAux:=FListOrdenantes[iOrdenanteFound].iPagos;

FListOrdenantes[iOrdenanteFound].mSumaImportes:=FListOrdenantes[iOrdenanteFound].mSumaImportes+mImporte;
FmTotalImportes:=FmTotalImportes+mImporte;

FListOrdenantes[iOrdenanteFound].ListPagos[iPagosAux]:=TInfoPago.Create;
FListOrdenantes[iOrdenanteFound].ListPagos[iPagosAux].sIdPago:=sIdPago;
FListOrdenantes[iOrdenanteFound].ListPagos[iPagosAux].mImporte:=mImporte;
FListOrdenantes[iOrdenanteFound].ListPagos[iPagosAux].sBICBeneficiario:=sBICBeneficiario;
FListOrdenantes[iOrdenanteFound].ListPagos[iPagosAux].sNombreBeneficiario:=sNombreBeneficiario;
FListOrdenantes[iOrdenanteFound].ListPagos[iPagosAux].sIBANBeneficiario:=sIBANBeneficiario;
FListOrdenantes[iOrdenanteFound].ListPagos[iPagosAux].sConcepto:=sConcepto;
end;

procedure TDJMNorma3414XML.AddOrdenante;
var
  lFound:Boolean;
  iAux:Integer;
begin
  if FiOrdenantes=10
  then begin
       ShowMessage('Solamente se admiten como máximo 10 Ordenantes');
       Exit;
       end;
  //si ya hay uno con esa cuenta, no lo añadimos
  lFound:=False;
  for iAux:=1 to FiOrdenantes
  do begin
     if FListOrdenantes[iAux].sIBANOrdenante = sIBANOrdenante
     then lFound:=True;
     end;
  if not lFound
  then begin
        FiOrdenantes:=FiOrdenantes+1;
        FListOrdenantes[FiOrdenantes]:=TInfoOrdenante.Create;
        FListOrdenantes[FiOrdenantes].mSumaImportes:=0;
        FListOrdenantes[FiOrdenantes].sPayMentId:=sPayMentId;
        FListOrdenantes[FiOrdenantes].sNombreOrdenante:=sNombreOrdenante;
        FListOrdenantes[FiOrdenantes].sIBANOrdenante:=sIBANOrdenante;
        FListOrdenantes[FiOrdenantes].sBICOrdenante:=sBICOrdenante;
        FListOrdenantes[FiOrdenantes].iPagos := 0;
       end; 
end;

function TDJMNorma3414XML.CalculateNumOperaciones;
var
  iOut:Integer;
  iOrdenantesAux:Integer;
begin
 iOut:=0;
 for iOrdenantesAux:=1 to FiOrdenantes
 do begin
    iOut:=iOut+FListOrdenantes[iOrdenantesAux].iPagos;
 end;
 Result:=iOut;
end;

function TDJMNorma3414XML.HayPagos;
begin
  Result:=FmTotalImportes<>0;
end;

end.
