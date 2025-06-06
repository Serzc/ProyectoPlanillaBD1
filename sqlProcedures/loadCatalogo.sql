BEGIN TRY
    BEGIN TRANSACTION;
    
    DECLARE @xmlData XML;

    -- Cargar el XML (copiar aquí el contenido completo de catalogos.xml)
    SET @xmlData = '
    <Catalogo>
<TiposdeDocumentodeIdentidad>
<TipoDocuIdentidad Id="1" Nombre="Cedula Nacional"/>
<TipoDocuIdentidad Id="2" Nombre="Cedula Residente"/>
<TipoDocuIdentidad Id="3" Nombre="Pasaporte"/>
<TipoDocuIdentidad Id="4" Nombre="Cedula Juridica"/>
<TipoDocuIdentidad Id="5" Nombre="Permiso de Trabajo"/>
<TipoDocuIdentidad Id="6" Nombre="Cedula Extranjera"/>
</TiposdeDocumentodeIdentidad>
<TiposDeJornada>
<TipoDeJornada Id="1" Nombre="Diurno" HoraInicio="06:00" HoraFin="14:00"/>
<TipoDeJornada Id="2" Nombre="Vespertino" HoraInicio="14:00" HoraFin="22:00"/>
<TipoDeJornada Id="3" Nombre="Nocturno" HoraInicio="22:00" HoraFin="06:00"/>
</TiposDeJornada>
<Puestos>
<Puesto Nombre="Electricista" SalarioXHora="1200"/>
<Puesto Nombre="Auxiliar de Laboratorio" SalarioXHora="1250"/>
<Puesto Nombre="Operador de Maquina" SalarioXHora="1025"/>
<Puesto Nombre="Soldador" SalarioXHora="1350"/>
<Puesto Nombre="Tecnico de Mantenimiento" SalarioXHora="1400"/>
<Puesto Nombre="Bodeguero" SalarioXHora="950"/>
</Puestos>
<Departamentos>
<Departamento Id="1" Nombre="Enlaminado"/>
<Departamento Id="2" Nombre="Laboratorio"/>
<Departamento Id="3" Nombre="Bodega de materiales"/>
<Departamento Id="4" Nombre="Bodega de producto terminado"/>
</Departamentos>
<Feriados>
<Feriado Id="1" Nombre="Día de Año Nuevo" Fecha="20230101"/>
<Feriado Id="2" Nombre="Día de Juan Santamaría" Fecha="20230411"/>
<Feriado Id="3" Nombre="Jueves Santo" Fecha="20230406"/>
<Feriado Id="4" Nombre="Viernes Santo" Fecha="20230407"/>
<Feriado Id="5" Nombre="Día del Trabajo" Fecha="20230501"/>
<Feriado Id="6" Nombre="Anexión del Partido de Nicoya" Fecha="20230725"/>
<Feriado Id="7" Nombre="Día de la Virgen de los Ángeles" Fecha="20230802"/>
<Feriado Id="8" Nombre="Día de la Madre" Fecha="20230815"/>
<Feriado Id="9" Nombre="Día de la Independencia" Fecha="20230915"/>
<Feriado Id="10" Nombre="Día de las Culturas" Fecha="20231012"/>
<Feriado Id="11" Nombre="Navidad" Fecha="20231225"/>
</Feriados>
<TiposDeMovimiento>
<TipoDeMovimiento Id="1" Nombre="Credito Horas ordinarias"/>
<TipoDeMovimiento Id="2" Nombre="Credito Horas Extra Normales"/>
<TipoDeMovimiento Id="3" Nombre="Credito Horas Extra Dobles"/>
<TipoDeMovimiento Id="4" Nombre="Debito Deducciones de Ley"/>
<TipoDeMovimiento Id="5" Nombre="Debito Deduccion No Obligatoria"/>
</TiposDeMovimiento>
<TiposDeDeduccion>
<TipoDeDeduccion Id="1" Nombre="Obligatorio de Ley" Obligatorio="Si" Porcentual="Si" Valor="0.095"/>
<TipoDeDeduccion Id="2" Nombre="Ahorro Asociacion Solidarista" Obligatorio="No" Porcentual="Si" Valor="0.05"/>
<TipoDeDeduccion Id="3" Nombre="Ahorro Vacacional" Obligatorio="No" Porcentual="No" Valor="0"/>
<TipoDeDeduccion Id="4" Nombre="Pension Alimenticia" Obligatorio="No" Porcentual="No" Valor="0"/>
</TiposDeDeduccion>
<Errores>
<Error Codigo="50001" Descripcion="Username no existe"/>
<Error Codigo="50002" Descripcion="Password no existe"/>
<Error Codigo="50003" Descripcion="Login deshabilitado"/>
<Error Codigo="50004" Descripcion="Empleado con ValorDocumentoIdentidad ya existe en inserción"/>
<Error Codigo="50005" Descripcion="Empleado con mismo nombre ya existe en inserción"/>
<Error Codigo="50006" Descripcion="Empleado con ValorDocumentoIdentidad ya existe en actualizacion"/>
<Error Codigo="50007" Descripcion="Empleado con mismo nombre ya existe en actualización"/>
<Error Codigo="50008" Descripcion="Error de base de datos"/>
<Error Codigo="50009" Descripcion="Nombre de empleado no alfabético"/>
<Error Codigo="50010" Descripcion="Valor de documento de identidad no alfabético"/>
</Errores>
<Usuarios>
<Usuario Id="1" Username="Goku" Password="1234" Tipo="1"/>
<Usuario Id="2" Username="Willy" Password="1234" Tipo="1"/>
<Usuario Id="3" Username="Pepe" Password="1234" Tipo="2"/>
<Usuario Id="4" Username="Lola" Password="1234" Tipo="2"/>
<Usuario Id="5" Username="emp1" Password="1234" Tipo="2"/>
<Usuario Id="6" Username="emp2" Password="1234" Tipo="2"/>
<Usuario Id="7" Username="emp3" Password="1234" Tipo="2"/>
<Usuario Id="8" Username="emp4" Password="1234" Tipo="2"/>
<Usuario Id="9" Username="emp5" Password="1234" Tipo="2"/>
<Usuario Id="10" Username="emp6" Password="1234" Tipo="2"/>
<Usuario Id="11" Username="emp7" Password="1234" Tipo="2"/>
<Usuario Id="12" Username="emp8" Password="1234" Tipo="2"/>
<Usuario Id="13" Username="emp9" Password="1234" Tipo="2"/>
<Usuario Id="14" Username="emp10" Password="1234" Tipo="2"/>
<Usuario Id="15" Username="emp11" Password="1234" Tipo="2"/>
<Usuario Id="16" Username="emp12" Password="1234" Tipo="2"/>
<Usuario Id="17" Username="emp13" Password="1234" Tipo="2"/>
<Usuario Id="18" Username="emp14" Password="1234" Tipo="2"/>
<Usuario Id="19" Username="emp15" Password="1234" Tipo="2"/>
<Usuario Id="20" Username="emp16" Password="1234" Tipo="2"/>
<Usuario Id="21" Username="emp17" Password="1234" Tipo="2"/>
<Usuario Id="22" Username="emp18" Password="1234" Tipo="2"/>
<Usuario Id="23" Username="emp19" Password="1234" Tipo="2"/>
<Usuario Id="24" Username="emp20" Password="1234" Tipo="2"/>
<Usuario Id="25" Username="emp21" Password="1234" Tipo="2"/>
<Usuario Id="26" Username="emp22" Password="1234" Tipo="2"/>
<Usuario Id="27" Username="emp23" Password="1234" Tipo="2"/>
<Usuario Id="28" Username="emp24" Password="1234" Tipo="2"/>
<Usuario Id="29" Username="emp25" Password="1234" Tipo="2"/>
<Usuario Id="30" Username="emp26" Password="1234" Tipo="2"/>
<Usuario Id="31" Username="emp27" Password="1234" Tipo="2"/>
<Usuario Id="32" Username="emp28" Password="1234" Tipo="2"/>
<Usuario Id="33" Username="emp29" Password="1234" Tipo="2"/>
<Usuario Id="34" Username="emp30" Password="1234" Tipo="2"/>
<Usuario Id="35" Username="emp31" Password="1234" Tipo="2"/>
<Usuario Id="36" Username="emp32" Password="1234" Tipo="2"/>
<Usuario Id="37" Username="emp33" Password="1234" Tipo="2"/>
<Usuario Id="38" Username="emp34" Password="1234" Tipo="2"/>
<Usuario Id="39" Username="emp35" Password="1234" Tipo="2"/>
<Usuario Id="40" Username="emp36" Password="1234" Tipo="2"/>
<Usuario Id="41" Username="emp37" Password="1234" Tipo="2"/>
<Usuario Id="42" Username="emp38" Password="1234" Tipo="2"/>
<Usuario Id="43" Username="emp39" Password="1234" Tipo="2"/>
<Usuario Id="44" Username="emp40" Password="1234" Tipo="2"/>
<Usuario Id="45" Username="emp41" Password="1234" Tipo="2"/>
<Usuario Id="46" Username="emp42" Password="1234" Tipo="2"/>
<Usuario Id="47" Username="emp43" Password="1234" Tipo="2"/>
<Usuario Id="48" Username="emp44" Password="1234" Tipo="2"/>
<Usuario Id="49" Username="emp45" Password="1234" Tipo="2"/>
<Usuario Id="50" Username="emp46" Password="1234" Tipo="2"/>
<Usuario Id="51" Username="emp47" Password="1234" Tipo="2"/>
<Usuario Id="52" Username="emp48" Password="1234" Tipo="2"/>
<Usuario Id="53" Username="emp49" Password="1234" Tipo="2"/>
<Usuario Id="54" Username="emp50" Password="1234" Tipo="2"/>
<Usuario Id="55" Username="emp51" Password="1234" Tipo="2"/>
<Usuario Id="56" Username="emp52" Password="1234" Tipo="2"/>
<Usuario Id="57" Username="emp53" Password="1234" Tipo="2"/>
<Usuario Id="58" Username="emp54" Password="1234" Tipo="2"/>
<Usuario Id="59" Username="emp55" Password="1234" Tipo="2"/>
<Usuario Id="60" Username="emp56" Password="1234" Tipo="2"/>
<Usuario Id="61" Username="emp57" Password="1234" Tipo="2"/>
<Usuario Id="62" Username="emp58" Password="1234" Tipo="2"/>
<Usuario Id="63" Username="emp59" Password="1234" Tipo="2"/>
<Usuario Id="64" Username="emp60" Password="1234" Tipo="2"/>
</Usuarios>
<UsuariosAdministradores>
<UsuarioAdministrador IdUsuario="1"/>
<UsuarioAdministrador IdUsuario="2"/>
</UsuariosAdministradores>
<TiposdeEvento>
<TipoEvento Id="1" Nombre="login"/>
<TipoEvento Id="2" Nombre="logout"/>
<TipoEvento Id="3" Nombre="Listar empleados"/>
<TipoEvento Id="4" Nombre="Listar empleados con filtro"/>
<TipoEvento Id="5" Nombre="Insertar empleado"/>
<TipoEvento Id="6" Nombre="Eliminar empleado"/>
<TipoEvento Id="7" Nombre="Asociar deduccion"/>
<TipoEvento Id="8" Nombre="DesaAsociar deduccion"/>
<TipoEvento Id="9" Nombre="Consultar una planilla semanal"/>
<TipoEvento Id="10" Nombre="Consultar una planilla mensual"/>
</TiposdeEvento>
<Empleados>
<Empleado Nombre="Eugene Cosby" IdTipoDocumento="1" ValorDocumento="2-544-447" FechaNacimiento="1977-10-21" IdDepartamento="1" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="5" Activo="1"/>
<Empleado Nombre="Mary Spieth" IdTipoDocumento="1" ValorDocumento="1-106-326" FechaNacimiento="1984-04-09" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="6" Activo="1"/>
<Empleado Nombre="Debra Bui" IdTipoDocumento="1" ValorDocumento="2-246-685" FechaNacimiento="1997-06-25" IdDepartamento="3" NombrePuesto="Bodeguero" IdUsuario="7" Activo="1"/>
<Empleado Nombre="Robyn Walsh" IdTipoDocumento="1" ValorDocumento="6-784-681" FechaNacimiento="1985-09-03" IdDepartamento="3" NombrePuesto="Soldador" IdUsuario="8" Activo="1"/>
<Empleado Nombre="Samuel Melo" IdTipoDocumento="1" ValorDocumento="2-544-826" FechaNacimiento="1985-05-14" IdDepartamento="4" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="9" Activo="1"/>
<Empleado Nombre="Robert Benson" IdTipoDocumento="1" ValorDocumento="2-276-161" FechaNacimiento="1979-04-21" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="10" Activo="1"/>
<Empleado Nombre="Henry Foster" IdTipoDocumento="1" ValorDocumento="7-976-311" FechaNacimiento="1979-12-10" IdDepartamento="2" NombrePuesto="Electricista" IdUsuario="11" Activo="1"/>
<Empleado Nombre="Cynthia Bahl" IdTipoDocumento="1" ValorDocumento="4-898-460" FechaNacimiento="1999-04-08" IdDepartamento="3" NombrePuesto="Electricista" IdUsuario="12" Activo="1"/>
<Empleado Nombre="Patricia Daniel" IdTipoDocumento="1" ValorDocumento="4-522-771" FechaNacimiento="1979-08-17" IdDepartamento="3" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="13" Activo="1"/>
<Empleado Nombre="Donald Davis" IdTipoDocumento="1" ValorDocumento="7-276-162" FechaNacimiento="1993-01-11" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="14" Activo="1"/>
<Empleado Nombre="Mi Starkey" IdTipoDocumento="1" ValorDocumento="5-473-844" FechaNacimiento="1982-11-09" IdDepartamento="2" NombrePuesto="Bodeguero" IdUsuario="15" Activo="1"/>
<Empleado Nombre="Carlos Mcclellan" IdTipoDocumento="1" ValorDocumento="3-247-580" FechaNacimiento="1981-05-05" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="16" Activo="1"/>
<Empleado Nombre="Anthony Taylor" IdTipoDocumento="1" ValorDocumento="2-629-450" FechaNacimiento="1997-09-25" IdDepartamento="3" NombrePuesto="Soldador" IdUsuario="17" Activo="1"/>
<Empleado Nombre="Rafael Cordova" IdTipoDocumento="1" ValorDocumento="6-527-305" FechaNacimiento="1965-06-24" IdDepartamento="4" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="18" Activo="1"/>
<Empleado Nombre="Robert Kruger" IdTipoDocumento="1" ValorDocumento="6-954-666" FechaNacimiento="1969-08-22" IdDepartamento="2" NombrePuesto="Operador de Maquina" IdUsuario="19" Activo="1"/>
<Empleado Nombre="Debi Matthews" IdTipoDocumento="1" ValorDocumento="3-566-411" FechaNacimiento="1983-10-04" IdDepartamento="3" NombrePuesto="Operador de Maquina" IdUsuario="20" Activo="1"/>
<Empleado Nombre="Myra Smith" IdTipoDocumento="1" ValorDocumento="5-971-361" FechaNacimiento="1983-12-03" IdDepartamento="2" NombrePuesto="Operador de Maquina" IdUsuario="21" Activo="1"/>
<Empleado Nombre="Alan Lusk" IdTipoDocumento="1" ValorDocumento="4-301-918" FechaNacimiento="1973-05-18" IdDepartamento="1" NombrePuesto="Operador de Maquina" IdUsuario="22" Activo="1"/>
<Empleado Nombre="Marisa Bair" IdTipoDocumento="1" ValorDocumento="4-431-166" FechaNacimiento="1975-01-06" IdDepartamento="2" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="23" Activo="1"/>
<Empleado Nombre="Arleen Garcia" IdTipoDocumento="1" ValorDocumento="2-205-405" FechaNacimiento="2002-03-21" IdDepartamento="2" NombrePuesto="Bodeguero" IdUsuario="24" Activo="1"/>
<Empleado Nombre="Leah Shepherd" IdTipoDocumento="1" ValorDocumento="7-289-248" FechaNacimiento="1995-08-17" IdDepartamento="1" NombrePuesto="Electricista" IdUsuario="25" Activo="1"/>
<Empleado Nombre="Valery Sturges" IdTipoDocumento="1" ValorDocumento="1-454-778" FechaNacimiento="2002-07-14" IdDepartamento="2" NombrePuesto="Electricista" IdUsuario="26" Activo="1"/>
<Empleado Nombre="Anthony Turner" IdTipoDocumento="1" ValorDocumento="7-592-594" FechaNacimiento="1990-12-23" IdDepartamento="4" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="27" Activo="1"/>
<Empleado Nombre="Julie Kohm" IdTipoDocumento="1" ValorDocumento="2-744-165" FechaNacimiento="1971-10-26" IdDepartamento="4" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="28" Activo="1"/>
<Empleado Nombre="Mildred Jones" IdTipoDocumento="1" ValorDocumento="5-577-956" FechaNacimiento="1979-09-27" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="29" Activo="1"/>
<Empleado Nombre="Ronald Bauer" IdTipoDocumento="1" ValorDocumento="6-425-594" FechaNacimiento="1986-01-05" IdDepartamento="2" NombrePuesto="Operador de Maquina" IdUsuario="30" Activo="1"/>
<Empleado Nombre="Harrison Johnson" IdTipoDocumento="1" ValorDocumento="2-870-240" FechaNacimiento="1991-05-11" IdDepartamento="4" NombrePuesto="Soldador" IdUsuario="31" Activo="1"/>
<Empleado Nombre="William Zeck" IdTipoDocumento="1" ValorDocumento="7-710-199" FechaNacimiento="1977-04-10" IdDepartamento="2" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="32" Activo="1"/>
<Empleado Nombre="Michael Weekly" IdTipoDocumento="1" ValorDocumento="5-843-257" FechaNacimiento="1997-12-01" IdDepartamento="1" NombrePuesto="Electricista" IdUsuario="33" Activo="1"/>
<Empleado Nombre="Colleen Inlow" IdTipoDocumento="1" ValorDocumento="6-283-622" FechaNacimiento="2005-09-01" IdDepartamento="4" NombrePuesto="Soldador" IdUsuario="34" Activo="1"/>
<Empleado Nombre="Dori Wang" IdTipoDocumento="1" ValorDocumento="7-108-482" FechaNacimiento="1992-03-12" IdDepartamento="4" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="35" Activo="1"/>
<Empleado Nombre="Evelyn Epps" IdTipoDocumento="1" ValorDocumento="1-595-336" FechaNacimiento="1976-09-24" IdDepartamento="4" NombrePuesto="Bodeguero" IdUsuario="36" Activo="1"/>
<Empleado Nombre="Sean Morton" IdTipoDocumento="1" ValorDocumento="2-703-219" FechaNacimiento="1972-09-01" IdDepartamento="3" NombrePuesto="Operador de Maquina" IdUsuario="37" Activo="1"/>
<Empleado Nombre="Rebecca Lam" IdTipoDocumento="1" ValorDocumento="6-813-391" FechaNacimiento="1983-01-16" IdDepartamento="1" NombrePuesto="Bodeguero" IdUsuario="38" Activo="1"/>
<Empleado Nombre="Britney Brown" IdTipoDocumento="1" ValorDocumento="2-536-208" FechaNacimiento="2005-08-02" IdDepartamento="3" NombrePuesto="Bodeguero" IdUsuario="39" Activo="1"/>
<Empleado Nombre="Shirley Orr" IdTipoDocumento="1" ValorDocumento="5-390-823" FechaNacimiento="1990-12-21" IdDepartamento="4" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="40" Activo="1"/>
<Empleado Nombre="Ray Evans" IdTipoDocumento="1" ValorDocumento="5-337-998" FechaNacimiento="2002-08-13" IdDepartamento="3" NombrePuesto="Electricista" IdUsuario="41" Activo="1"/>
<Empleado Nombre="Judy Pao" IdTipoDocumento="1" ValorDocumento="7-434-623" FechaNacimiento="1992-06-11" IdDepartamento="4" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="42" Activo="1"/>
<Empleado Nombre="Anthony Bruder" IdTipoDocumento="1" ValorDocumento="2-853-332" FechaNacimiento="1999-03-08" IdDepartamento="3" NombrePuesto="Bodeguero" IdUsuario="43" Activo="1"/>
<Empleado Nombre="Brian Takaki" IdTipoDocumento="1" ValorDocumento="6-999-607" FechaNacimiento="2001-04-21" IdDepartamento="1" NombrePuesto="Bodeguero" IdUsuario="44" Activo="1"/>
<Empleado Nombre="Cheryl Arzu" IdTipoDocumento="1" ValorDocumento="6-865-818" FechaNacimiento="1984-06-10" IdDepartamento="3" NombrePuesto="Electricista" IdUsuario="45" Activo="1"/>
<Empleado Nombre="Sterling Brady" IdTipoDocumento="1" ValorDocumento="4-289-519" FechaNacimiento="1983-06-18" IdDepartamento="1" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="46" Activo="1"/>
<Empleado Nombre="Ashley Harding" IdTipoDocumento="1" ValorDocumento="2-539-319" FechaNacimiento="1993-10-17" IdDepartamento="2" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="47" Activo="1"/>
<Empleado Nombre="Caren Goodermote" IdTipoDocumento="1" ValorDocumento="1-769-354" FechaNacimiento="1980-10-08" IdDepartamento="1" NombrePuesto="Operador de Maquina" IdUsuario="48" Activo="1"/>
<Empleado Nombre="Juan Guptill" IdTipoDocumento="1" ValorDocumento="7-804-727" FechaNacimiento="1988-06-10" IdDepartamento="1" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="49" Activo="1"/>
<Empleado Nombre="Michael William" IdTipoDocumento="1" ValorDocumento="1-366-665" FechaNacimiento="1987-08-26" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="50" Activo="1"/>
<Empleado Nombre="Sandra Wardell" IdTipoDocumento="1" ValorDocumento="6-880-519" FechaNacimiento="1991-09-01" IdDepartamento="2" NombrePuesto="Soldador" IdUsuario="51" Activo="1"/>
<Empleado Nombre="Grace Montgomery" IdTipoDocumento="1" ValorDocumento="1-878-294" FechaNacimiento="2005-03-17" IdDepartamento="3" NombrePuesto="Electricista" IdUsuario="52" Activo="1"/>
<Empleado Nombre="Cynthia Rogers" IdTipoDocumento="1" ValorDocumento="1-635-539" FechaNacimiento="2005-06-12" IdDepartamento="1" NombrePuesto="Bodeguero" IdUsuario="53" Activo="1"/>
<Empleado Nombre="Marvin Nipper" IdTipoDocumento="1" ValorDocumento="3-326-402" FechaNacimiento="1972-01-20" IdDepartamento="1" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="54" Activo="1"/>
<Empleado Nombre="Kimberly Guerra" IdTipoDocumento="1" ValorDocumento="6-695-989" FechaNacimiento="1984-01-27" IdDepartamento="2" NombrePuesto="Tecnico de Mantenimiento" IdUsuario="55" Activo="1"/>
<Empleado Nombre="Karl Newman" IdTipoDocumento="1" ValorDocumento="7-982-376" FechaNacimiento="1967-01-03" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="56" Activo="1"/>
<Empleado Nombre="Joshua Sparks" IdTipoDocumento="1" ValorDocumento="2-635-784" FechaNacimiento="1965-11-22" IdDepartamento="4" NombrePuesto="Operador de Maquina" IdUsuario="57" Activo="1"/>
<Empleado Nombre="Charles Klein" IdTipoDocumento="1" ValorDocumento="3-673-781" FechaNacimiento="1982-09-26" IdDepartamento="4" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="58" Activo="1"/>
<Empleado Nombre="Tracy Garrett" IdTipoDocumento="1" ValorDocumento="6-252-824" FechaNacimiento="2005-12-27" IdDepartamento="3" NombrePuesto="Electricista" IdUsuario="59" Activo="1"/>
<Empleado Nombre="Betty Sauls" IdTipoDocumento="1" ValorDocumento="4-147-188" FechaNacimiento="1974-10-01" IdDepartamento="3" NombrePuesto="Operador de Maquina" IdUsuario="60" Activo="1"/>
<Empleado Nombre="Rafael Smith" IdTipoDocumento="1" ValorDocumento="5-677-230" FechaNacimiento="2000-11-16" IdDepartamento="2" NombrePuesto="Soldador" IdUsuario="61" Activo="1"/>
<Empleado Nombre="Brian Campbell" IdTipoDocumento="1" ValorDocumento="4-829-751" FechaNacimiento="1967-09-01" IdDepartamento="2" NombrePuesto="Auxiliar de Laboratorio" IdUsuario="62" Activo="1"/>
<Empleado Nombre="Clayton Sanders" IdTipoDocumento="1" ValorDocumento="5-512-538" FechaNacimiento="1989-06-16" IdDepartamento="3" NombrePuesto="Soldador" IdUsuario="63" Activo="1"/>
<Empleado Nombre="Kimberly Meyer" IdTipoDocumento="1" ValorDocumento="7-155-242" FechaNacimiento="2001-03-05" IdDepartamento="4" NombrePuesto="Electricista" IdUsuario="64" Activo="1"/>
</Empleados>
</Catalogo>
	';

    -- 1. Cargar Tipos de Documento de Identidad
    INSERT INTO TipoDocumentoIdentidad (id, Nombre)
    SELECT 
        doc.value('@Id', 'INT'),
        doc.value('@Nombre', 'VARCHAR(50)')
    FROM @xmlData.nodes('/Catalogo/TiposdeDocumentodeIdentidad/TipoDocuIdentidad') AS T(doc)
    WHERE NOT EXISTS (SELECT 1 FROM TipoDocumentoIdentidad WHERE id = doc.value('@Id', 'INT'));

    -- 2. Cargar Tipos de Jornada
    INSERT INTO TipoJornada (id, Nombre, HoraInicio, HoraFin)
    SELECT 
        jornada.value('@Id', 'INT'),
        jornada.value('@Nombre', 'VARCHAR(50)'),
        CAST(jornada.value('@HoraInicio', 'VARCHAR(8)') AS TIME),
        CAST(jornada.value('@HoraFin', 'VARCHAR(8)') AS TIME)
    FROM @xmlData.nodes('/Catalogo/TiposDeJornada/TipoDeJornada') AS T(jornada)
    WHERE NOT EXISTS (SELECT 1 FROM TipoJornada WHERE id = jornada.value('@Id', 'INT'));

    -- 3. Cargar Puestos
    INSERT INTO Puesto (Nombre, SalarioXHora)
    SELECT 
        puesto.value('@Nombre', 'VARCHAR(100)'),
        puesto.value('@SalarioXHora', 'DECIMAL(10,2)')
    FROM @xmlData.nodes('/Catalogo/Puestos/Puesto') AS T(puesto)
    WHERE NOT EXISTS (SELECT 1 FROM Puesto WHERE Nombre = puesto.value('@Nombre', 'VARCHAR(100)'));

    -- 4. Cargar Departamentos
    INSERT INTO Departamento (id, Nombre)
    SELECT 
        depto.value('@Id', 'INT'),
        depto.value('@Nombre', 'VARCHAR(100)')
    FROM @xmlData.nodes('/Catalogo/Departamentos/Departamento') AS T(depto)
    WHERE NOT EXISTS (SELECT 1 FROM Departamento WHERE id = depto.value('@Id', 'INT'));

    -- 5. Cargar Feriados
    INSERT INTO Feriado (id, Nombre, Fecha)
    SELECT 
        feriado.value('@Id', 'INT'),
        feriado.value('@Nombre', 'VARCHAR(100)'),
        CASE 
            WHEN ISDATE(feriado.value('@Fecha', 'VARCHAR(8)')) = 1 
            THEN CAST(feriado.value('@Fecha', 'VARCHAR(8)') AS DATE)
            ELSE NULL
        END
    FROM @xmlData.nodes('/Catalogo/Feriados/Feriado') AS T(feriado)
    WHERE NOT EXISTS (SELECT 1 FROM Feriado WHERE id = feriado.value('@Id', 'INT'));

    -- 6. Cargar Tipos de Movimiento
    INSERT INTO TipoMovimiento (id, Nombre)
    SELECT 
        mov.value('@Id', 'INT'),
        mov.value('@Nombre', 'VARCHAR(100)')
    FROM @xmlData.nodes('/Catalogo/TiposDeMovimiento/TipoDeMovimiento') AS T(mov)
    WHERE NOT EXISTS (SELECT 1 FROM TipoMovimiento WHERE id = mov.value('@Id', 'INT'));

    -- 7. Cargar Tipos de Deducción
    INSERT INTO TipoDeduccion (id, Nombre, Obligatorio, Porcentual, Valor)
    SELECT 
        ded.value('@Id', 'INT'),
        ded.value('@Nombre', 'VARCHAR(100)'),
        CASE WHEN ded.value('@Obligatorio', 'VARCHAR(2)') = 'Si' THEN 1 ELSE 0 END,
        CASE WHEN ded.value('@Porcentual', 'VARCHAR(2)') = 'Si' THEN 1 ELSE 0 END,
        ded.value('@Valor', 'DECIMAL(10,2)')
    FROM @xmlData.nodes('/Catalogo/TiposDeDeduccion/TipoDeDeduccion') AS T(ded)
    WHERE NOT EXISTS (SELECT 1 FROM TipoDeduccion WHERE id = ded.value('@Id', 'INT'));

    -- 8. Cargar Tipos de Evento
    INSERT INTO TipoEvento (id, Nombre)
    SELECT 
        evento.value('@Id', 'INT'),
        evento.value('@Nombre', 'VARCHAR(100)')
    FROM @xmlData.nodes('/Catalogo/TiposdeEvento/TipoEvento') AS T(evento)
    WHERE NOT EXISTS (SELECT 1 FROM TipoEvento WHERE id = evento.value('@Id', 'INT'));

    INSERT INTO TipoError (id, Descripcion)
    SELECT 
        error.value('@Codigo', 'INT'),
        error.value('@Descripcion', 'VARCHAR(255)')
    FROM @xmlData.nodes('/Catalogo/Errores/Error') AS T(error)
    WHERE NOT EXISTS (SELECT 1 FROM TipoError WHERE Codigo = error.value('@Codigo', 'INT'));


    -- 9. Cargar Usuarios
    INSERT INTO Usuario (Username, Password, Tipo, idEmpleado)
    SELECT 
        usuario.value('@Username', 'VARCHAR(50)'),
        usuario.value('@Password', 'VARCHAR(100)'),
        usuario.value('@Tipo', 'INT'),
        NULL -- Temporalmente NULL, se actualizará después
    FROM @xmlData.nodes('/Catalogo/Usuarios/Usuario') AS T(usuario)
    WHERE NOT EXISTS (SELECT 1 FROM Usuario WHERE Username = usuario.value('@Username', 'VARCHAR(50)'));

    -- 10. Cargar Empleados (versión corregida)
    DECLARE @EmpleadosTemp TABLE (
        idUsuario INT,
        Nombre VARCHAR(100),
        idTipoDocumento INT,
        ValorDocumentoIdentidad VARCHAR(50),
        FechaNacimiento DATE,
        FechaContratacion DATE,
        idDepartamento INT,
        NombrePuesto VARCHAR(100),
        Activo BIT
    );

    -- Extraer datos de empleados a tabla temporal
    INSERT INTO @EmpleadosTemp
    SELECT 
        emp.value('@IdUsuario', 'INT'),
        emp.value('@Nombre', 'VARCHAR(100)'),
        emp.value('@IdTipoDocumento', 'INT'),
        emp.value('@ValorDocumento', 'VARCHAR(50)'),
        CASE 
            WHEN ISDATE(emp.value('@FechaNacimiento', 'VARCHAR(10)')) = 1 
            THEN CAST(emp.value('@FechaNacimiento', 'VARCHAR(10)') AS DATE)
            ELSE NULL
        END,
        GETDATE(), -- FechaContratacion por defecto
        emp.value('@IdDepartamento', 'INT'),
        emp.value('@NombrePuesto', 'VARCHAR(100)'),
        CASE WHEN emp.value('@Activo', 'VARCHAR(1)') = '1' THEN 1 ELSE 0 END
    FROM @xmlData.nodes('/Catalogo/Empleados/Empleado') AS T(emp);

    -- Insertar empleados con los puestos correctos
    INSERT INTO Empleado (
        Nombre, idTipoDocumento, ValorDocumentoIdentidad, 
        FechaNacimiento, FechaContratacion, idPuesto, 
        idDepartamento, Activo
    )
    SELECT 
        t.Nombre,
        t.idTipoDocumento,
        t.ValorDocumentoIdentidad,
        t.FechaNacimiento,
        t.FechaContratacion,
        p.id,
        t.idDepartamento,
        t.Activo
    FROM @EmpleadosTemp t
    INNER JOIN Puesto p ON p.Nombre = t.NombrePuesto
    WHERE NOT EXISTS (
        SELECT 1 FROM Empleado 
        WHERE ValorDocumentoIdentidad = t.ValorDocumentoIdentidad
    );

    -- Actualizar usuarios con los IDs de empleado
    UPDATE u
    SET u.idEmpleado = e.id
    FROM Usuario u
    INNER JOIN @EmpleadosTemp t ON u.id = t.idUsuario
    INNER JOIN Empleado e ON e.ValorDocumentoIdentidad = t.ValorDocumentoIdentidad
    WHERE u.idEmpleado IS NULL;

    -- Asignar deducciones obligatorias a los nuevos empleados
    INSERT INTO EmpleadoDeduccion (idEmpleado, idTipoDeduccion, ValorPorcentual, ValorFijo)
    SELECT 
        e.id,
        td.id,
        CASE WHEN td.Porcentual = 1 THEN td.Valor ELSE NULL END,
        CASE WHEN td.Porcentual = 0 THEN td.Valor ELSE NULL END
    FROM Empleado e
    CROSS JOIN TipoDeduccion td
    WHERE td.Obligatorio = 1
    AND NOT EXISTS (
        SELECT 1 FROM EmpleadoDeduccion ed 
        WHERE ed.idEmpleado = e.id AND ed.idTipoDeduccion = td.id
    )
    AND e.id IN (
        SELECT e2.id FROM Empleado e2
        INNER JOIN @EmpleadosTemp t ON e2.ValorDocumentoIdentidad = t.ValorDocumentoIdentidad
    );

    -- Mostrar resumen de lo cargado
    SELECT 'Tipos de Documento' AS Tabla, COUNT(*) AS Registros FROM TipoDocumentoIdentidad
    UNION ALL
    SELECT 'Tipos de Jornada', COUNT(*) FROM TipoJornada
    UNION ALL
    SELECT 'Puestos', COUNT(*) FROM Puesto
    UNION ALL
    SELECT 'Departamentos', COUNT(*) FROM Departamento
    UNION ALL
    SELECT 'Feriados', COUNT(*) FROM Feriado
    UNION ALL
    SELECT 'Tipos de Movimiento', COUNT(*) FROM TipoMovimiento
    UNION ALL
    SELECT 'Tipos de Deducción', COUNT(*) FROM TipoDeduccion
    UNION ALL
    SELECT 'Tipos de Evento', COUNT(*) FROM TipoEvento
    UNION ALL
    SELECT 'Usuarios', COUNT(*) FROM Usuario
    UNION ALL
    SELECT 'Empleados', COUNT(*) FROM Empleado
    UNION ALL
    SELECT 'Deducciones de Empleados', COUNT(*) FROM EmpleadoDeduccion;

    COMMIT TRANSACTION;
    PRINT 'Todos los datos fueron cargados exitosamente.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Error durante la carga de datos:';
    PRINT 'Mensaje: ' + ERROR_MESSAGE();
    PRINT 'Número: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT 'Procedimiento: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
    
    -- Mostrar qué tablas tienen datos (para diagnóstico)
    SELECT 
        OBJECT_NAME(object_id) AS Tabla, 
        SUM(row_count) AS Filas
    FROM sys.dm_db_partition_stats
    WHERE object_id IN (
        OBJECT_ID('TipoDocumentoIdentidad'),
        OBJECT_ID('TipoJornada'),
        OBJECT_ID('Puesto'),
        OBJECT_ID('Departamento'),
        OBJECT_ID('Feriado'),
        OBJECT_ID('TipoMovimiento'),
        OBJECT_ID('TipoDeduccion'),
        OBJECT_ID('TipoEvento'),
        OBJECT_ID('Usuario'),
        OBJECT_ID('Empleado'),
        OBJECT_ID('EmpleadoDeduccion')
    )
    AND index_id < 2
    GROUP BY object_id;
END CATCH;