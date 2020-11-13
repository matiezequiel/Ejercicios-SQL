--Ejercicio 1 ✔
GO

CREATE FUNCTION dbo.OcupacionDepositoE1 (@art varchar(8),@depo char(2))
RETURNS varchar(30)
AS
BEGIN 
	DECLARE @result DECIMAL(12,2)
	(
		SELECT @result = ISNULL((S.stoc_cantidad*100) / S.stoc_stock_maximo,0)
		FROM STOCK S
		WHERE S.stoc_producto = @art AND S.stoc_deposito = @depo
	)
RETURN
	CASE
		WHEN @result < 100
		THEN 
			('Ocupacion del Deposito: ' + CONVERT(varchar(10),@result) + '%')
		ELSE
			'Deposito Completo'
	END
END

GO
select prod_codigo, dbo.OcupacionDepositoE1(prod_codigo, '00') from Producto
select dbo.OcupacionDepositoE1(00010211, '00')
GO

--Ejercicio 2 ✔
CREATE FUNCTION dbo.StockFechaE2(@art varchar(8), @fecha datetime)
RETURNS decimal(12,2)
AS
BEGIN
RETURN (SELECT SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto = @art) + 
       (SELECT SUM(item_cantidad)
		FROM Item_Factura
		JOIN Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
		WHERE item_producto = @art AND fact_fecha >= @fecha)
END

GO

--Ejercicio 3
CREATE PROC dbo.Ejercicio3(@empleados_sin_jefe decimal(12,0) OUTPUT)
AS
BEGIN
SET @empleados_sin_jefe = (SELECT COUNT(DISTINCT empl_codigo) FROM Empleado WHERE empl_jefe is NULL)
DECLARE @gerente_general numeric(6,0) = (SELECT TOP 1 empl_codigo FROM Empleado WHERE empl_jefe is NULL ORDER BY empl_salario DESC, empl_ingreso ASC)
WHILE ( SELECT COUNT(*)
		FROM Empleado E
		WHERE E.empl_jefe IS NULL) > 1 
BEGIN
UPDATE Empleado SET empl_jefe = @gerente_general
	WHERE empl_jefe IS NULL
		AND empl_codigo <> @gerente_general
END 
RETURN @empleados_sin_jefe
END

DECLARE @empleadosSinJefe numeric(6,0)
EXEC Ejercicio3 @empleados_sin_jefe =  @empleadosSinJefe OUTPUT
SELECT @empleadosSinJefe

SELECT * FROM Empleado
SELECT * FROM Empleado WHERE empl_jefe is NULL ORDER BY empl_ingreso ASC
INSERT INTO Empleado
VALUES (11,'Pablo','Delucchi','1991-01-01 00:00:00','2015-01-01 00:00:00','Gerente',29000,0,NULL,1)

GO

--Ejercicio 4
CREATE PROC dbo.Ejercicio4 (@empl_mas_vendio numeric(6,0) OUTPUT)
AS
BEGIN
SET @empl_mas_vendio = (SELECT TOP 1 fact_vendedor FROM Factura
                                         WHERE YEAR(fact_fecha) = 2012
                                         GROUP BY fact_vendedor
										 ORDER BY SUM(fact_total) DESC)

UPDATE Empleado SET empl_comision = (SELECT SUM(fact_total) FROM Factura
	                                 WHERE YEAR(fact_fecha) = 2012 and fact_vendedor = empl_codigo)

RETURN @empl_mas_vendio	 
END

DECLARE @vendedor_que_mas_vendio numeric(6,0)
EXEC Ejercicio4 @empl_mas_vendio = @vendedor_que_mas_vendio OUTPUT
SELECT @vendedor_que_mas_vendio AS [Vendedor que mas vendio]
select * from Empleado

GO

--Ejercicio 5
Create table Fact_table(
anio char(4) NOT NULL, --YEAR(fact_fecha)
mes char(2) NOT NULL, --RIGHT('0' + convert(varchar(2),MONTH(fact_fecha)),2)
familia char(3) NOT NULL,--prod_familia
rubro char(4) NOT NULL,--prod_rubro
zona char(3) NOT NULL,--depa_zona
cliente char(6) NOT NULL,--fact_cliente
producto char(8) NOT NULL,--item_producto
cantidad decimal(12,2) NOT NULL,--item_cantidad
monto decimal(12,2)--asumo que es item_precio debido a que es por cada producto, 
				   --asumo tambien que el precio ya esta determinado por total y no por unidad (no debe multiplicarse por cantidad)
)

Alter table Fact_table
Add constraint pk_Fact_table_ID primary key(anio,mes,familia,rubro,zona,cliente,producto)


CREATE PROC dbo.Ejercicio5
AS
BEGIN 
     INSERT INTO Fact_table
	 SELECT YEAR(fact_fecha), RIGHT('0' + convert(varchar(2),MONTH(fact_fecha)),2), prod_familia, prod_rubro
		,depa_zona, fact_cliente, prod_codigo, SUM(item_cantidad), sum(item_precio)
	 FROM Factura F
	 JOIN Item_Factura IFACT ON IFACT.item_tipo =f.fact_tipo AND IFACT.item_sucursal = F.fact_sucursal AND IFACT.item_numero = F.fact_numero
	 JOIN Producto P ON P.prod_codigo = IFACT.item_producto
	 JOIN Empleado E ON E.empl_codigo = F.fact_vendedor
	 JOIN Departamento D ON D.depa_codigo = E.empl_departamento
	 GROUP BY YEAR(fact_fecha), RIGHT('0' + convert(varchar(2),MONTH(fact_fecha)),2), prod_familia, prod_rubro,
		      depa_zona, fact_cliente, prod_codigo
END

EXEC Ejercicio5
SELECT * FROM Fact_table

GO

--Ejercicio 6
CREATE PROC dbo.Ejercicio6
AS
BEGIN
     DECLARE @numero_fact char(8)
	 DECLARE @sucu_fact char(4)
	 DECLARE @tipo_fact char(1) 
	 DECLARE @combo char(8)
	 DECLARE @comboCantidad int
	 DECLARE cFactura CURSOR FOR SELECT fact_numero, fact_sucursal, fact_tipo FROM Factura
	 OPEN cFactura
	 FETCH NEXT FROM cFactura INTO @numero_fact, @sucu_fact, @tipo_fact
	 WHILE @@FETCH_STATUS = 0
	 BEGIN
          DECLARE cProd CURSOR FOR SELECT comp_producto FROM Item_Factura
		                           JOIN Composicion C1 on (item_producto = C1.comp_componente)
								   WHERE item_cantidad >= C1.comp_cantidad AND item_sucursal + item_numero + item_tipo = @numero_fact + @sucu_fact + @tipo_fact
								   GROUP BY C1.comp_producto
								   HAVING COUNT(*) = (SELECT COUNT(*) FROM Composicion C2 WHERE C2.comp_producto = C1.comp_producto) 
		  OPEN cProd
		  FETCH NEXT FROM cProd INTO @COMBO
		  WHILE @@FETCH_STATUS = 0
		  BEGIN
		       SELECT @comboCantidad = MIN(FLOOR((item_cantidad/C1.comp_cantidad))) 
			   FROM Item_Factura JOIN Composicion C1 on (item_producto = C1.comp_componente)
			   WHERE item_cantidad >= C1.comp_cantidad AND C1.comp_producto = @combo 
			         AND item_sucursal + item_numero + item_tipo = @numero_fact + @sucu_fact + @tipo_fact
			   
			   INSERT INTO Item_Factura(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
			   SELECT @tipo_fact, @sucu_fact, @numero_fact, @combo, @comboCantidad,(SELECT prod_precio FROM Producto where prod_codigo = @combo)
			   
			   UPDATE Item_Factura
			   SET item_cantidad = I1.item_cantidad - (@comboCantidad * (SELECT comp_cantidad FROM Composicion
			                                                             WHERE I1.item_producto=comp_componente AND comp_producto=@combo))
			   FROM Item_Factura I1, Composicion C1
			   WHERE I1.item_producto = C1.comp_componente AND I1.item_sucursal + I1.item_numero + I1.item_tipo = @numero_fact + @sucu_fact + @tipo_fact
			   
			   DELETE FROM Item_Factura
			   WHERE item_sucursal + item_numero + item_tipo = @numero_fact + @sucu_fact + @tipo_fact AND item_cantidad = 0

			   FETCH NEXT FROM cProd INTO @COMBO
		  END
		  CLOSE cProd
		  DEALLOCATE cProd
		  
		  FETCH NEXT FROM cFactura INTO @numero_fact, @sucu_fact, @tipo_fact
								
	END
	CLOSE cFactura
	DEALLOCATE cFactura
END

GO

--Ejercicio 7
Create table Ventas(
vent_codigo char(8) NULL, --Código del articulo
vent_detalle char(50) NULL, --Detalle del articulo
vent_movimientos int NULL, --Cantidad de movimientos de ventas (Item Factura)
vent_precio_prom decimal(12,2) NULL, --Precio promedio de venta
vent_renglon int IDENTITY(1,1) PRIMARY KEY, --Nro de linea de la tabla (PK)
vent_ganancia char(6) NOT NULL, --Precio de venta - Cantidad * Costo Actual
)
Alter table Ventas
Add constraint pk_ventas_ID primary key(vent_renglon)

GO

CREATE PROC dbo.Ejercicio7(@fecha_inicio datetime, @fecha_fin datetime)
AS
BEGIN
     DECLARE cFact CURSOR FOR SELECT item_producto, prod_detalle, SUM(item_cantidad), AVG(item_cantidad * item_precio), SUM(fact_total - item_precio * item_cantidad) FROM Factura
	                          JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
							  JOIN Producto ON item_producto = prod_codigo
							  WHERE fact_fecha > @fecha_inicio AND fact_fecha < @fecha_fin
							  GROUP BY item_producto, prod_detalle
							  ORDER BY prod_detalle DESC

	 DECLARE @venta_codigo char(8)
	 DECLARE @venta_detalle char(50)
	 DECLARE @venta_movimientos int
	 DECLARE @venta_precio_promedio decimal(12,2)
	 DECLARE @venta_ganancia char(6)

	 OPEN cFact
	 FETCH NEXT FROM cFact INTO @venta_codigo, @venta_detalle, @venta_movimientos, @venta_precio_promedio, @venta_ganancia

	 WHILE @@FETCH_STATUS = 0
	      BEGIN
	           INSERT INTO Ventas(vent_codigo, vent_detalle, vent_movimientos, vent_precio_prom, vent_ganancia)
			          SELECT @venta_codigo, @venta_detalle, @venta_movimientos, @venta_precio_promedio, @venta_ganancia
			   FETCH NEXT FROM cFact INTO @venta_codigo, @venta_detalle, @venta_movimientos, @venta_precio_promedio, @venta_ganancia
		  END
	CLOSE cFact
	DEALLOCATE cFact
END

GO

--Ejercicio 8
CREATE TABLE Diferencias(
	dif_codigo char(8) NULL
	,dif_detalle char(50) NULL
	,dif_cantidad int NULL
	,dif_precio_generado decimal(12,2) NULL
	,dif_precio_facturado decimal(12,2) NULL
)

GO

CREATE FUNCTION dbo.PrecioProductoE8 (@codigo_prod char(8))
RETURNS decimal(12,2)
AS
BEGIN 
     DECLARE cComp CURSOR FOR SELECT comp_componente, comp_cantidad, prod_precio FROM Composicion
	                          JOIN Producto ON prod_codigo = comp_componente
	                          WHERE comp_producto = @codigo_prod
	 DECLARE @precio decimal(12,2)
	 DECLARE @codigo_comp char(8)
	 DECLARE @precio_comp decimal(12,2)
	 DECLARE @cant_comp decimal(12,2)
	 SET @precio=0

	 OPEN cComp
	 FETCH NEXT FROM cComp INTO @codigo_comp, @cant_comp, @precio_comp
	 WHILE @@FETCH_STATUS = 0
	      BEGIN
		       SET @precio = CASE WHEN (SELECT COUNT(*) FROM Composicion WHERE comp_producto = @codigo_comp) > 0
			                 THEN dbo.Ejercicio11(@codigo_comp) + @precio
							 ELSE (@cant_comp * @precio_comp) + @precio END
		       FETCH NEXT FROM cComp INTO @codigo_comp, @cant_comp, @precio_comp
		  END
	CLOSE cComp
	DEALLOCATE cComp
	RETURN @precio
END

GO 

select dbo.PrecioProductoE8('00001104')

select * from Composicion JOIN Producto ON prod_codigo=comp_componente where comp_producto = '00001104'
select * from producto WHERE prod_codigo = '00001104'

GO

CREATE PROC dbo.Ejercicio8PROC
AS
BEGIN
     DECLARE cFact CURSOR FOR SELECT fact_total, item_producto, COUNT(DISTINCT comp_componente) FROM Factura
	                          JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
                              JOIN Composicion ON comp_producto = item_producto GROUP BY fact_total, item_producto
     DECLARE @codigo_prod char(8)
	 DECLARE @precio_facturado decimal(12,2)
	 DECLARE @detalle char(50)
	 DECLARE @cant_combo int
	 DECLARE @precio_generado decimal(12,2)

	 OPEN cFact
	 FETCH NEXT FROM cFact INTO @precio_facturado, @codigo_prod, @cant_combo

	 WHILE @@FETCH_STATUS = 0
	      BEGIN
		       IF((SELECT dbo.Ejercicio8(@codigo_prod)) <> @precio_facturado)
			     BEGIN
					  SET @detalle = (SELECT prod_detalle FROM Producto WHERE prod_codigo = @codigo_prod)
					  SET @precio_generado = (SELECT dbo.PrecioProductoE8(@codigo_prod))
					  INSERT INTO Diferencias(dif_codigo, dif_detalle, dif_cantidad, dif_precio_generado, dif_precio_facturado)
					  SELECT @codigo_prod, @detalle, @cant_combo, @precio_generado, @precio_facturado
				 END

			   FETCH NEXT FROM cFact INTO @precio_facturado, @codigo_prod, @cant_combo
		  END
END 

GO

--Ejercicio 9 ✔
CREATE TRIGGER dbo.Ejercicio9 ON Item_factura FOR UPDATE
AS
BEGIN
      DECLARE cComp CURSOR FOR SELECT ((I.item_cantidad - D.item_cantidad) * comp_cantidad), comp_componente FROM Item_Factura Ifact
	                           JOIN Composicion ON Ifact.item_producto = comp_producto
		                       JOIN INSERTED I ON comp_componente = I.item_producto JOIN DELETED D ON comp_componente = D.item_producto
							   WHERE I.item_cantidad != D.item_cantidad
	  DECLARE @cant_comp decimal(12,0)
	  DECLARE @codigo_comp char(8)

	  OPEN cComp
	  FETCH NEXT FROM cComp INTO @cant_comp, @codigo_comp
	  	
	  WHILE @@FETCH_STATUS = 0
	       BEGIN
		        UPDATE STOCK set stoc_cantidad = stoc_cantidad -@cant_comp
				       WHERE stoc_producto = @codigo_comp  and stoc_deposito = (SELECT TOP 1 depo_codigo FROM DEPOSITO
					                                                            WHERE stoc_producto = @codigo_comp ORDER BY stoc_cantidad DESC )
		        FETCH NEXT FROM cComp INTO @cant_comp, @codigo_comp
		   END
	  CLOSE cComp
	  DEALLOCATE cComp

END

GO

select * from Item_Factura
select * from DEPOSITO
select * from STOCK
order by stoc_producto

GO

--Ejercicio 10
--INSTEAD OF
CREATE TRIGGER Ejercicio10 ON Producto FOR DELETE
AS
BEGIN
     IF (SELECT SUM(stoc_cantidad) FROM STOCK
	 JOIN DELETED D ON stoc_producto = D.prod_codigo
	 GROUP BY stoc_producto) > 0
	 BEGIN 
		ROLLBACK TRANSACTION
		PRINT 'No se puede borrar porque el articulo tiene stock'
	 END
     ELSE 
	 BEGIN
	     DELETE FROM STOCK
		 WHERE stoc_producto IN (SELECT prod_codigo FROM deleted)
		 DELETE FROM Producto WHERE prod_codigo IN (SELECT prod_codigo FROM deleted)
	 END
END	      

GO

--Ejercicio 11 ✔
CREATE FUNCTION dbo.CantidadEmpleadosE11 (@codigo_empl numeric(6,0))
RETURNS INT
AS
BEGIN
DECLARE @empleado numeric(6,0)
DECLARE @cant_empleados INT = (SELECT COUNT(*) FROM Empleado
                               WHERE empl_jefe = @codigo_empl)


DECLARE cEmpl cursor FOR SELECT empl_codigo FROM Empleado WHERE empl_jefe = @codigo_empl
OPEN cEmpl
FETCH NEXT FROM cEmpl INTO @empleado
WHILE @@FETCH_STATUS = 0
     BEGIN
	 SET @cant_empleados = @cant_empleados + dbo.Ejercicio11(@empleado) 
	 FETCH NEXT FROM cEmpl INTO @empleado
	 END
CLOSE cEmpl
DEALLOCATE cEmpl
RETURN @cant_empleados
END

GO

UPDATE Empleado set empl_jefe = NULL from Empleado where empl_codigo = 10
DELETE Empleado where empl_codigo = 11
select * from Empleado

select dbo.CantidadEmpleadosE11(10)

GO

--Ejercicio 12 ✔
CREATE FUNCTION CompuestoPorSiMismoE12(@producto char(8), @composicion char(8))
RETURNS INT
AS
BEGIN
    IF(@producto = @composicion)
      RETURN 1
    ELSE
        BEGIN
        DECLARE cComp CURSOR FOR SELECT comp_componente FROM Composicion
                            WHERE comp_producto = @producto
        DECLARE @prod_aux char(8)
        OPEN cComp
        FETCH NEXT FROM cComp INTO @prod_aux
        WHILE @@FETCH_STATUS = 0
             BEGIN
	         IF(@prod_aux = @composicion)
		       RETURN 1
	         FETCH NEXT FROM cEmpl INTO @prod_aux
	         END
        CLOSE cEmpl
        DEALLOCATE cEmpl
   END
RETURN 0
END

GO

CREATE TRIGGER Ejercicio12_1 ON Composicion FOR INSERT, UPDATE
AS
BEGIN
     IF(SELECT COUNT(*) FROM INSERTED WHERE dbo.CompuestoPorSiMismoE12(comp_producto, comp_componente) = 1) > 0
       BEGIN
	   PRINT 'No puede ingresarse un producto compuesto por si mismo'
	   ROLLBACK 
	   END
END

GO

CREATE TRIGGER Ejercicio12_2 ON Composicion INSTEAD OF INSERT, UPDATE
AS
BEGIN
     IF(SELECT COUNT(*) FROM DELETED) = 0  --SI ES UN INSERT =>
	   IF(SELECT COUNT(*) FROM INSERTED WHERE dbo.CompuestoPorSiMismoE12(comp_producto, comp_componente) = 1) > 0
	      PRINT 'No puede ingresarse un producto compuesto por si mismo'
	   ELSE
	      INSERT Composicion SELECT * FROM INSERTED WHERE dbo.Ejercicio12(comp_producto, comp_componente) = 0
	 ELSE --SI ES UN UPDATE =>
	     BEGIN
		 DECLARE @productodel char(8)
		 DECLARE @componentedel char(8)
		 DECLARE @cantdel decimal(12,2)
		 DECLARE cProductosdel CURSOR FOR SELECT comp_producto, comp_componente, comp_cantidad FROM DELETED
		 DECLARE @producto char(8)
		 DECLARE @componente char(8)
		 DECLARE @cant decimal(12,2)
		 DECLARE cProductos CURSOR FOR SELECT comp_producto, comp_componente, comp_cantidad FROM INSERTED
		 OPEN cProductosdel
		 OPEN cProductos
		 FETCH NEXT FROM cProductosdel into @productodel, @componentedel, @cantdel
		 FETCH NEXT FROM cProductos into @producto, @componente, @cant
		 WHILE @@FETCH_STATUS = 0
		 BEGIN
		      IF(SELECT dbo.CompuestoPorSiMismoE12(@producto,@componente)) = 0
			    BEGIN
				     DELETE Composicion WHERE comp_producto = @productodel AND comp_componente = @componentedel
				     INSERT Composicion values(@producto, @componente, @cant)
				END
			  ELSE
			      PRINT 'No puede ingresarse un producto compuesto por si mismo'
			 FETCH NEXT FROM cProductosdel into @productodel, @componentedel, @cantdel
		     FETCH NEXT FROM cProductos into @producto, @componente, @cant
	     END
		 CLOSE cProductos
		 DEALLOCATE cProductos
		 CLOSE cProductosdel
		 DEALLOCATE cProductosdel
	 END
END

GO

--Ejercicio 13
CREATE FUNCTION dbo.SumaSalarioEmpleadosE13 (@codigo_jefe numeric(6))
RETURNS decimal(12,2)
AS
BEGIN
     DECLARE cEmpl CURSOR FOR SELECT empl_salario, empl_codigo FROM Empleado
	                          WHERE empl_jefe = @codigo_jefe
	 DECLARE @suma_salarios decimal(12,2)
	 DECLARE @codigo_empl numeric(6)
	 DECLARE @ingreso_empl decimal(12,2)
	 SET @suma_salarios = 0

	 OPEN cEmpl
	 FETCH NEXT FROM cEmpl INTO @ingreso_empl, @codigo_empl

	 WHILE @@FETCH_STATUS = 0
	 BEGIN
		  SET @suma_salarios = @ingreso_empl + @suma_salarios + dbo.SumaSalarioEmpleados(@codigo_empl)
		  FETCH NEXT FROM cEmpl INTO @ingreso_empl, @codigo_empl
	 END
	 CLOSE cEmpl
	 DEALLOCATE cEmpl
	 RETURN @suma_salarios
END

GO

select dbo.SumaSalarioEmpleadosE13(1)
select * from Empleado

GO

CREATE TRIGGER Ejercicio13 ON Empleado FOR UPDATE
AS
BEGIN 
     IF EXISTS(SELECT empl_salario FROM INSERTED 
	           WHERE empl_salario > (dbo.SumaSalarioEmpleados(empl_codigo) *0.2) )
	 BEGIN
	 PRINT 'El salario no puede ser mayor al 20% de las sumas de los salarios de sus empleados totales'
	 ROLLBACK
	 END
END

GO

--Ejercicio 14
CREATE TRIGGER Ejerccicio14 ON Item_factura FOR INSERT
AS
BEGIN
     DECLARE @fecha smalldatetime
	 DECLARE @cliente char(6)
	 DECLARE @prod_item char(8)
	 DECLARE @precio_item decimal(12,2)
	 DECLARE @cant_item decimal(12,2)
	 DECLARE @tipo_item char 
	 DECLARE @suc_item char(4)
	 DECLARE @num_item char (8)
	 DECLARE cIfact CURSOR FOR SELECT I.item_tipo, I.item_sucursal, I.item_numero, I.item_producto, I.item_cantidad, I.item_precio FROM INSERTED I 
	                           JOIN Composicion C ON C.comp_producto = I.item_producto
	 OPEN cIfact
	 FETCH NEXT FROM cIfact INTO @tipo_item, @suc_item, @num_item, @prod_item, @cant_item, @precio_item

	 WHILE @@FETCH_STATUS = 0
	 BEGIN
	      IF(@precio_item > dbo.precioProducto15(@prod_item) / 2)
		    BEGIN
			     INSERT Item_Factura VALUES(@tipo_item, @suc_item, @num_item, @prod_item, @cant_item, @precio_item)
				 SELECT @fecha=fact_fecha, @cliente = fact_cliente FROM Factura WHERE fact_numero+fact_sucursal+fact_tipo = @tipo_item+@suc_item+@num_item
				 PRINT 'FECHA: ' + @fecha + ' CLIENTE: '+ @cliente + ' PRODUCTO: ' + @prod_item + ' PRECIO: ' + @precio_item 

			END
		  ELSE
		    BEGIN
			     DELETE FROM Factura WHERE fact_numero+fact_sucursal+fact_tipo = @tipo_item+@suc_item+@num_item
			     DELETE FROM Item_Factura WHERE item_numero+item_sucursal+item_tipo = @tipo_item+@suc_item+@num_item
				 PRINT 'No se puede vender un combo a un precio menor al 50% de la suma del precio de todos sus componentes'
			END
	      FETCH NEXT FROM cIfact INTO @tipo_item, @suc_item, @num_item, @prod_item, @cant_item, @precio_item
	 END	  
	 CLOSE cIfact
	 DEALLOCATE cIfact
END

GO
--Ejercicio 15  
CREATE FUNCTION dbo.PrecioProductoE15 (@codigo_prod char(8))
RETURNS decimal(12,2)
AS
BEGIN
     DECLARE @precio decimal(12,2)
	 IF( (SELECT COUNT(*) FROM Composicion WHERE comp_producto = @codigo_prod) > 0)
	 BEGIN
	      DECLARE cComp CURSOR FOR SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @codigo_prod
		  DECLARE @codigo_comp char(8)
		  DECLARE @cant_comp decimal(12,2)
		  SET @precio=0

		  OPEN cComp
		  FETCH NEXT FROM cComp INTO @codigo_comp, @cant_comp
		  WHILE @@FETCH_STATUS = 0
		  BEGIN     
			   SET @precio = @precio + (SELECT (prod_precio * @cant_comp) FROM Producto WHERE prod_codigo = @codigo_comp)
			   FETCH NEXT FROM cComp INTO @codigo_comp, @cant_comp
		  END

		  CLOSE cComp
		  DEALLOCATE cComp

	 END
	 ELSE
	 BEGIN
	      SET @precio = (SELECT prod_precio FROM Producto WHERE prod_codigo = @codigo_prod)
	 END
	 RETURN @PRECIO
END
	 
GO

--Ejercicio 16
CREATE TRIGGER Ejercicio16 ON Factura FOR INSERT
AS
BEGIN
     DECLARE cProd CURSOR FOR SELECT item_producto, item_cantidad FROM INSERTED I
	                          JOIN Item_Factura ON item_tipo+item_numero+item_sucursal = I.fact_tipo+I.fact_numero+I.fact_sucursal
							  WHERE item_producto not in (SELECT comp_producto FROM Composicion)
	 DECLARE @codigo_prod char(8)
	 DECLARE @cant decimal(12,2)

	 OPEN cProd
	 FETCH NEXT FROM cProd INTO @codigo_prod, @cant

	 WHILE @@FETCH_STATUS = 0
	      BEGIN
		       UPDATE STOCK set stoc_cantidad = stoc_cantidad - @cant
			                WHERE stoc_deposito = (SELECT TOP 1 stoc_deposito FROM STOCK
												   WHERE stoc_producto = @codigo_prod
												   ORDER BY(stoc_cantidad) DESC)
		       FETCH NEXT FROM cProd INTO @codigo_prod, @cant
		  END
	 CLOSE cProd
	 DEALLOCATE cProd

	 DECLARE cComp CURSOR FOR SELECT comp_componente, (item_cantidad * comp_cantidad) FROM INSERTED I
	                          JOIN Item_Factura ON item_tipo+item_numero+item_sucursal = I.fact_tipo+I.fact_numero+I.fact_sucursal
							  JOIN Composicion ON comp_producto = item_producto

	 OPEN cComp
	 FETCH NEXT FROM cComp INTO @codigo_prod, @cant

	 WHILE @@FETCH_STATUS = 0
	      BEGIN
		       UPDATE STOCK set stoc_cantidad = stoc_cantidad - @cant
			                WHERE stoc_deposito = (SELECT TOP 1 stoc_deposito FROM STOCK
												   WHERE stoc_producto = @codigo_prod
												   ORDER BY(stoc_cantidad) DESC)
		       FETCH NEXT FROM cComp INTO @codigo_prod, @cant
		  END
	 CLOSE cComp
	 DEALLOCATE cComp
END

GO

--Ejercicio 17
CREATE TRIGGER Ejercicio17 ON STOCK FOR INSERT, UPDATE
AS
BEGIN
     IF((SELECT COUNT(*) FROM INSERTED I WHERE I.stoc_cantidad < I.stoc_punto_reposicion) > 0)
	   BEGIN
	        PRINT 'El stock del producto se encuentra por debajo del minimo'
	   END

	 IF((SELECT COUNT(*) FROM INSERTED I WHERE I.stoc_cantidad > I.stoc_stock_maximo) > 0)
	   BEGIN
	        PRINT 'Se exta excediendo la cantidad maxima de stock del producto'
			ROLLBACK
	   END
	   
END

GO

--Ejercicio 18
CREATE TRIGGER Ejercicio18 ON Factura FOR INSERT, UPDATE
AS
BEGIN
     IF((SELECT COUNT(*) FROM INSERTED I WHERE I.fact_total > ((SELECT (clie_limite_credito) FROM Cliente WHERE clie_codigo = fact_cliente)
	                                                           -(SELECT SUM(fact_total) FROM Factura WHERE MONTH(I.fact_fecha) = MONTH(fact_fecha) AND YEAR(I.fact_fecha) = YEAR(fact_fecha)))) >0)  
	   BEGIN
	        PRINT 'El monto de la factura es mayor al credito del cliente'
			ROLLBACK
	   END
END

GO

--Ejercicio 19
CREATE TRIGGER ReglaJefeE19 ON Empleado FOR INSERT, UPDATE
AS
BEGIN
     IF( (SELECT COUNT(*) FROM INSERTED I WHERE dbo.CantidadEmpleadosE11(I.empl_jefe) > (SELECT COUNT(*)*0.5 FROM Empleado)
	                                            AND YEAR(CURRENT_TIMESTAMP) - YEAR(I.empl_ingreso) >= 5 ) > 0)
	   BEGIN
	        PRINT 'Ningun jefe puede tener mas del %50 del personal a su cargo ni tener menos de 5 años de antiguedad'
	        ROLLBACK
	   END
END

GO

--Ejercicio 20
CREATE TRIGGER ComisionesActualizadasE20 ON Factura FOR INSERT
AS
BEGIN
     DECLARE @codigo_empl numeric(6,0)
	 DECLARE @comision decimal(12,2)
	 DECLARE @cant_item int
	 DECLARE cEmpl CURSOR FOR SELECT I.fact_vendedor, SUM(Ifact.item_cantidad * Ifact.item_precio) *0.05, COUNT(DISTINCT Ifact.item_precio) FROM INSERTED I
	                          JOIN Item_Factura Ifact ON Ifact.item_numero + Ifact.item_sucursal + Ifact.item_tipo = I.fact_numero + I.fact_sucursal + I.fact_tipo
							  GROUP BY I.fact_vendedor
							  
	 OPEN cEmpl
	 FETCH NEXT FROM cEmpl INTO @codigo_empl, @comision, @cant_item 

	 WHILE @@FETCH_STATUS = 0
	      BEGIN
		       SET @comision = @comision + (SELECT SUM(Ifact.item_cantidad * Ifact.item_precio) FROM Factura F
                                            JOIN Item_Factura Ifact ON Ifact.item_numero + Ifact.item_sucursal + Ifact.item_tipo = F.fact_numero + F.fact_sucursal + F.fact_tipo
											WHERE F.fact_vendedor = @codigo_empl and MONTH(getdate()) = MONTH(F.fact_fecha))
                
			    IF(SELECT COUNT(DISTINCT Ifact.item_producto) FROM Factura F
                   JOIN Item_Factura Ifact ON Ifact.item_numero + Ifact.item_sucursal + Ifact.item_tipo = F.fact_numero + F.fact_sucursal + F.fact_tipo
				   WHERE F.fact_vendedor = @codigo_empl and MONTH(getdate()) = MONTH(F.fact_fecha) + @cant_item) >= 50
				   SET @comision = @comision * 1.3
			   
			    UPDATE Empleado SET empl_comision = @comision WHERE empl_codigo = @codigo_empl

				FETCH NEXT FROM cEmpl INTO @codigo_empl, @comision, @cant_item 
		  END
	 CLOSE cEmpl
	 DEALLOCATE cEmpl
END
