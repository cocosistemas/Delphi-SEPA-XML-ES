unit fMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfrMain = class(TForm)
    btnTestNorma19: TButton;
    btnTestNorma34: TButton;
    procedure btnTestNorma19Click(Sender: TObject);
    procedure btnTestNorma34Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frMain: TfrMain;

implementation
uses uDJMSepa1914XML, uDJMSepa3414XML;

{$R *.dfm}

procedure TfrMain.btnTestNorma19Click(Sender: TObject);
var
  oNorma1914:TDJMNorma1914XML;
begin
  oNorma1914:=TDJMNorma1914XML.create;
  //la info general del fichero
  //El id. del identificador te lo dará el Banco, LEER LAS NORMAS SEPA!!
  oNorma1914.SetInfoPresentador(Date,'NOMBRE DEL PRESENTADOR S.L.',
                               'ID.PRESENTADOR',date);
  //un Ordenante. Un presentador puede presentar las órdenes de varios ordenantes
  oNorma1914.AddOrdenante('ID UNICO DE LAS ORDENES DE ESTE ORDENANTE',
                          'EMPRESA ORDENANTE 1 S.L.',
                          'el iban de este ordenante',
                          'BicOrdenante1',
                          'ID.ORDENANTE'
                         );
  //las ordenes de cobro de este ordenante
  oNorma1914.AddCobro('idCobro unico', //utilizar un nº de documento o contador, etc
                      1200,
                      'id.mandato', //por ejemplo, poner un nº de contrato o del documento de la firma del mandato
                      StrToDate('31/10/2009'), //esta es la fecha por defecto de los que no tienen fecha de mandato
                      'Bic de este Deudor',
                      'Nombre Deudor 1 S.L.',
                      'IBAN De este Deudor',
                      'Cobro de pruebas factura nº 1',
                      'el iban de este ordenante' //importante, el cobro se coloca en su ordenante/cuenta de cobro
                      );
  //otra orden de cobro
  oNorma1914.AddCobro('idCobro unico-2', //utilizar un nº de documento o contador, etc
                      230,
                      'id.mandato',
                      StrToDate('31/10/2009'), //esta es la fecha por defecto de los que no tienen fecha de mandato
                      'Bic de este Deudor',
                      'Nombre Deudor 2 S.L.',
                      'IBAN De este Deudor',
                      'Cobro de pruebas factura nº 1',
                      'el iban de este ordenante' //importante, el cobro se coloca en su ordenante/cuenta de cobro
                      );
  if oNorma1914.hayCobros //en algún algoritmo te puede ser util comprobar que has añadido cobros
  then begin
       oNorma1914.createFile('test-1914.xml');
       oNorma1914.closeFile;
       showmessage('Fichero 1914 creado');
       end
  else showmessage('No hay cobros');
  oNorma1914.Free;
end;

procedure TfrMain.btnTestNorma34Click(Sender: TObject);
var
  oNorma3414:TDJMNorma3414XML;
begin
oNorma3414:=TDJMNorma3414XML.create;
//info del presentador
oNorma3414.SetInfoPresentador(date,'NOMBRE DEL PRESENTADOR',
                              'ID. DEL PRESENTADOR',
                              date);
//info del ordenante
oNorma3414.AddOrdenante('ID. UNICO DEL PAGO',
                        'NOMBRE DEL ORDENANTE S.L.',
                        'IBAN DEL ORDENANTE',
                        'BIC DEL ORDENANTE'
                        );
//Una orden de pago
oNorma3414.AddPago('ID UNICO DEL PAGO',
                   500,
                   'BIC DEL BENEFICIARIO',
                   'NOMBRE DEL BENEFICIARIO 1 S.L.',
                   'IBAN DEL BENEFICIARIO',
                   'Pago de su factura nº 5698',
                   'IBAN DEL ORDENANTE' //El mismo q añadimos con el ordenante
                   );
oNorma3414.CreateFile('test-3414.xml');
oNorma3414.closeFile;
ShowMessage('Fichero 34.14 creado');
oNorma3414.Free;
end;

end.
