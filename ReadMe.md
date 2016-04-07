# Delphi: Creación de ficheros normas 19.14 y 34.14 SEPA formato XML

Estas unidades contienen dos objetos para la creación de los siguientes ficheros:

- Norma 19.14 SEPA XML. Es un fichero de órdenes de cobro. El **ordenante** cobra al **deudor**. Internamente tenemos un array de ordenantes, cada uno con sus órdenes de cobro. Basta utilizar AddOrdenante, AddCobro. Como cada ordenante tiene una cuenta de abono para todos los cobros, internamente el objeto se encarga de colocar cada cobro en su ordenante. **Ver el test** está ahí explicado el uso de los objetos.

- Norma 34.14 SEPA XML. Es un fichero de órdenes de pago. El **ordenante** paga al **beneficiario**.

Cosas a tener en cuenta:

- **Leer la normativa de los dos ficheros**. Son complejos. Hay campos opcionales que no se han añadido aquí y puede que su banco se lo pida. Los identificadores únicos de cada elemento son importantes, hay que leer su significado y tomar la decisión de cómo formarlos. Por si fuera poco, cada banco tiene su interpretación y puede que le pida alguna variación en algún elemento del fichero (esto ya lo he comprobado con la versión anterior los 19.14 y 34.14 en formato plano). **Esto no es un componente "listo para usar" sin más**. Hay que entender de qué estamos hablando. Lo que si facilita es la estructuración y la escritura de las etiquetas.

- Como guardamos la info en arrays, hay unos límites de órdenes y ordenantes. Supongo que serán suficientes pero es fácilmente modificable.

- En la normativa hay muchos campos opcionales, no se ha añadido ninguno.

- Se trata de los esquemas básicos, no los b2b.

- Solamente se contemplan transferencias en euros, nada de cheques.

- No se contemplan órdenes de devoluciones, etc.

- No se hace ningún chequeo de contenidos (IBAN, BIC, etc)

- Vea el proyecto test de ejemplo.

- Basado en este otro componente: [https://github.com/aspettl/delphi-sepa-xml](https://github.com/aspettl/delphi-sepa-xml) las diferencias son amplias, pero es justo mencionar ese git.

La normativa: 
- Para la norma 34.14, buscar **Órdenes en formato ISO 20022 para emisión de transferencias y cheques en euros** por ejemplo [https://empresa.lacaixa.es/deployedfiles/empresas/Estaticos/pdf/Transferenciasyficheros/Cuaderno_34_XML_Noviembre_2015.pdf](https://empresa.lacaixa.es/deployedfiles/empresas/Estaticos/pdf/Transferenciasyficheros/Cuaderno_34_XML_Noviembre_2015.pdf) Si quiere puede ir directamente al **ANEXO 1**. Es la parte interesante etiqueta a etiqueta. La programación de este proyecto se realizó siguiendo este ANEXO 1 etiqueta a etiqueta. Ojo! hay documentos que están desactualizados, ojo a las fechas! El último que he encontrado es de Noviembre 2015

- Para la norma 19.14 buscar **Órdenes en formato ISO 20022 para emisión de adeudos directos SEPA en euros** por ejemplo [https://empresa.lacaixa.es/deployedfiles/empresas/Estaticos/pdf/Transferenciasyficheros/CuadernoXMLSDDCoreFebrero2014.pdf](https://empresa.lacaixa.es/deployedfiles/empresas/Estaticos/pdf/Transferenciasyficheros/CuadernoXMLSDDCoreFebrero2014.pdf)


Actualización (febrero 2016): Ya está testeado en 3 bancos españoles. Tanto la norma 19.14 como la 34.14 y los ficheros han sido aceptados.

Actualización (abril 2016): Hacemos público (en Norma 19.14) el array de ordenantes. Para poder recorrerlo y mostrarle al usuario el resumen de importes, algo así:

     for iOrdenantes:=1 to oNorma1914XML.iOrdenantes do begin
         mmFicheros.Lines.add(oNorma1914XML.listOrdenantes[iOrdenantes].sNombreOrdenante+' '+
              oNorma1914XML.listOrdenantes[iOrdenantes].sIBANOrdenante+' '+
                              uFmt_Numero2Str2(oNorma1914XML.listOrdenantes[iOrdenantes].mSumaImportes)+'€');
     end;


Espero que sea de utilidad.
Diego J. Muñoz. 
Freelance.
Cocosistemas.com