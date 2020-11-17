SELECT * FROM Envases -- 3 envases
SELECT * FROM Producto -- 2190 productos
SELECT * FROM Item_Factura -- 19484 item factura
SELECT * FROM Factura -- 3000 facturas
SELECT * FROM Rubro -- 31 rubros
SELECT * FROM Familia -- 95 familias
SELECT * FROM Stock -- 5564 stocks
SELECT * FROM DEPOSITO -- 33 depositos
SELECT * FROM  Empleado -- 9 empleados
SELECT * FROM Departamento -- 3 departamentos
SELECT * FROM Zona -- 20 zonas
SELECT * FROM Cliente -- 3687 clientes
SELECT comp_producto, SUM(comp_cantidad) FROM Composicion
GROUP BY comp_producto -- 6 productos composicion


--1 ✔ 15/09
SELECT clie_codigo, clie_razon_social FROM Cliente
WHERE clie_limite_credito >= 1000
ORDER BY clie_codigo


--2 ✔ 15/09
SELECT prod_codigo, prod_detalle, SUM(item_cantidad) 
FROM Item_Factura
JOIN Producto ON item_producto = prod_codigo 
JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY SUM(item_cantidad) DESC


--3 ✔
SELECT prod_codigo, prod_detalle, SUM(stoc_cantidad) as stock_total
FROM Producto
JOIN STOCK ON stoc_producto = prod_codigo
JOIN DEPOSITO ON depo_codigo = stoc_deposito
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle


--4 ✔
SELECT prod_codigo, prod_detalle, COUNT(DISTINCT comp_componente) as cant_componentes, AVG(stoc_cantidad) 
FROM Producto
JOIN STOCK ON stoc_producto = prod_codigo
JOIN DEPOSITO ON depo_codigo = stoc_deposito
LEFT OUTER JOIN Composicion ON prod_codigo = comp_producto
GROUP BY prod_codigo, prod_detalle, comp_producto
--HAVING AVG(stoc_cantidad) > 100
ORDER BY COUNT( DISTINCT comp_cantidad) DESC

SELECT comp_producto,comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = 00006402
GROUP BY comp_producto

SELECT comp_producto, comp_cantidad FROM Composicion
GROUP BY comp_producto, comp_cantidad


--5  ✔
SELECT prod_codigo, prod_detalle, SUM(item_cantidad) as cant_egresos_stock
FROM Producto
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
HAVING SUM(item_cantidad) > (SELECT SUM(I.item_cantidad)
                             FROM Item_Factura I
							 JOIN Factura F ON F.fact_tipo + F.fact_sucursal + F.fact_numero = I.item_tipo + I.item_sucursal + I.item_numero
							 WHERE YEAR(F.fact_fecha) = 2011 AND I.item_producto = prod_codigo)

--6 ✔
SELECT rubr_id, rubr_detalle, SUM(stoc_cantidad) as cant_stock, COUNT(DISTINCT prod_codigo) as cant_articulos
FROM Producto
JOIN Rubro ON prod_rubro = rubr_id
JOIN STOCK ON stoc_producto = prod_codigo
GROUP BY rubr_detalle, rubr_id
HAVING SUM(stoc_cantidad) > (select S.stoc_cantidad from STOCK S
					        WHERE (S.stoc_producto = '00000000' AND S.stoc_deposito = '00'))

--7 como hay precios distintos para el mismo item??
SELECT prod_codigo, prod_detalle, MIN(item_precio) as menor_precio, MAX(item_precio) as mayor_precio
FROM Producto
JOIN  Item_Factura ON item_producto = prod_codigo
JOIN STOCK ON stoc_producto = prod_codigo
WHERE stoc_cantidad > 0
GROUP BY prod_codigo, prod_detalle


--8  ✔
SELECT prod_detalle, SUM(stoc_cantidad), 
      (SELECT TOP 1 stoc_cantidad FROM STOCK S
	   WHERE prod_codigo = S.stoc_producto
	   ORDER BY S.stoc_cantidad DESC)
FROM Producto
JOIN STOCK ON stoc_producto = prod_codigo
JOIN DEPOSITO ON depo_codigo = stoc_deposito
GROUP BY prod_detalle, prod_codigo, stoc_cantidad
HAVING (count(DISTINCT stoc_deposito)) = (
		SELECT COUNT(depo_codigo)
		FROM DEPOSITO
		)

SELECT prod_detalle, stoc_cantidad FROM STOCK
JOIN Producto ON prod_codigo = stoc_producto


--9 29/09 ✔
SELECT empl_codigo, empl_jefe, empl_nombre, COUNT(DISTINCT depo_codigo) as depo_empleado
FROM Empleado
JOIN Departamento ON depa_codigo = empl_departamento
JOIN Zona ON zona_codigo = depa_zona
JOIN DEPOSITO ON depo_zona = zona_codigo
GROUP BY empl_codigo, empl_jefe, empl_nombre

SELECT empl_codigo, empl_jefe, empl_nombre, COUNT(DISTINCT depo_codigo) as depo_empleado
FROM Empleado
JOIN DEPOSITO ON depo_encargado = empl_codigo OR depo_encargado = empl_jefe
GROUP BY empl_codigo, empl_jefe, empl_nombre

--10 29/09 ✔

SELECT I2.item_producto, prod_detalle,SUM(I2.item_cantidad) AS Ventas,(SELECT TOP 1 f1.fact_cliente
                                       FROM Item_Factura i1
									   JOIN Factura f1 on f1.fact_tipo + f1.fact_sucursal + f1.fact_numero = i1.item_tipo + i1.item_sucursal + i1.item_numero
									   WHERE i1.item_producto= I2.item_producto
									   GROUP BY f1.fact_cliente
									   ORDER BY SUM(i1.item_cantidad) DESC) CLIENTE_QUE_MAS_COMRPO									   
FROM Producto
JOIN Item_Factura I2 ON I2.item_producto = prod_codigo 
JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = I2.item_tipo + I2.item_sucursal + I2.item_numero
WHERE I2.item_producto IN (SELECT TOP 10 item_producto 
                           FROM Producto
						   JOIN Item_Factura ON item_producto = prod_codigo
						   GROUP BY item_producto
						   ORDER BY SUM(item_cantidad) DESC)
OR I2.item_producto IN (SELECT TOP 10 item_producto
                        FROM Producto
						JOIN Item_Factura ON item_producto = prod_codigo
						GROUP BY item_producto
						ORDER BY SUM(item_cantidad) ASC)
GROUP BY I2.item_producto, prod_detalle
ORDER BY SUM(I2.item_cantidad) DESC


--11  ✔
SELECT fami_detalle, COUNT(DISTINCT prod_codigo) as prod_diferentes, SUM(item_cantidad * item_precio) as monto
FROM Familia
JOIN Producto ON fami_id = prod_familia
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
WHERE YEAR(fact_fecha) = 2012 
GROUP BY fami_detalle
HAVING SUM(item_cantidad * item_precio ) > 20000
ORDER BY COUNT(DISTINCT prod_codigo) DESC


--12 ✔
SELECT prod_detalle, COUNT(DISTINCT fact_cliente) as cant_compradores, AVG(item_precio) as precio_promedio,
       (SELECT COUNT(DISTINCT depo_codigo)
	    FROM DEPOSITO
		JOIN STOCK ON stoc_deposito = depo_codigo
		WHERE stoc_cantidad > 0 AND prod_codigo = stoc_producto
		GROUP BY stoc_producto) as cant_depositos,
		(SELECT SUM(stoc_cantidad)
	    FROM DEPOSITO
		JOIN STOCK ON stoc_deposito = depo_codigo
		WHERE prod_codigo = stoc_producto
		GROUP BY stoc_producto) as cant_stock
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
WHERE YEAR(fact_fecha) = 2012 
GROUP BY prod_detalle, prod_codigo
ORDER BY SUM(fact_total) DESC

--esto trae los registros multiplicados por la cantidad de stock
SELECT prod_detalle, fact_numero, stoc_cantidad, depa_codigo, item_cantidad
FROM Producto
JOIN STOCK on stoc_producto = prod_codigo
JOIN Departamento on depa_codigo = stoc_deposito
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
WHERE YEAR(fact_fecha) = 2012
ORDER BY prod_detalle DESC


--13 ✔
SELECT COMBO.prod_detalle,COMBO.prod_precio,SUM(Componente.prod_precio * C.comp_cantidad)
FROM Producto COMBO
JOIN Composicion C ON C.comp_producto = COMBO.prod_codigo
JOIN Producto Componente ON Componente.prod_codigo = C.comp_componente
GROUP BY COMBO.prod_detalle,COMBO.prod_precio
HAVING COUNT(DISTINCT C.comp_cantidad) > 2 --no existen productos que tengan mas de 2 componentes 
ORDER BY COUNT(DISTINCT C.comp_cantidad)  DESC


--14 ✔
SELECT fact_cliente, COUNT(fact_cliente) AS cant_compras, AVG(fact_total) AS promedio_compras, 
       COUNT(DISTINCT item_producto) as productos_diferentes ,MAX(fact_total) as mayor_compra
FROM Factura
JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
WHERE  YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
GROUP BY fact_cliente
ORDER BY COUNT(fact_cliente) DESC

--15 ✔
SELECT I1.item_producto,P1.prod_detalle ,I2.item_producto, P2.prod_detalle, COUNT(*) as pepeeee
FROM Producto P1
JOIN Item_Factura I1 ON P1.prod_codigo = I1.item_producto
JOIN Item_Factura I2 ON  I1.item_tipo + I1.item_sucursal + I1.item_numero = I2.item_tipo + I2.item_sucursal + I2.item_numero
JOIN Producto P2 On I2.item_producto = P2.prod_codigo
WHERE I1.item_producto < I2.item_producto
GROUP BY I1.item_producto,P1.prod_detalle ,I2.item_producto, P2.prod_detalle
HAVING COUNT(*) > 500


--16 ✔
SELECT F1.fact_cliente as cliente, SUM(I1.item_cantidad) as unidades_vendidas, I1.item_producto as prod_mayor_venta
FROM Item_Factura I1
JOIN Factura F1 ON F1.fact_numero+F1.fact_sucursal+F1.fact_tipo = I1.item_numero+I1.item_sucursal+I1.item_tipo
WHERE YEAR(F1.fact_fecha) = 2012 AND I1.item_producto = (SELECT TOP 1 item_producto
                                                         FROM Item_Factura
                                                         JOIN Factura ON  item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
                                                         WHERE  YEAR(fact_fecha) = 2012 AND fact_cliente = F1.fact_cliente
											             GROUP BY item_cantidad, item_producto, item_precio
											             ORDER BY (item_cantidad*item_precio) DESC)
GROUP BY F1.fact_cliente , I1.item_producto
HAVING SUM(I1.item_cantidad*I1.item_precio) < (SELECT TOP 1 AVG(item_cantidad*item_precio) *0.3
                                               FROM Item_Factura
                                               JOIN Factura ON  item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
                                               WHERE  YEAR(fact_fecha) = 2012
											   GROUP BY item_cantidad, item_producto
											   ORDER BY item_cantidad DESC)
ORDER BY (SELECT clie_domicilio FROM Cliente WHERE clie_codigo = F1.fact_cliente)



--17 ✔
SELECT STR(YEAR(F1.fact_fecha)) + STR(MONTH(F1.fact_fecha)) as periodo ,P1.prod_codigo, P1.prod_detalle, 
       SUM(I1.item_cantidad) as cantidad_vendida, 
	   ISNULL((SELECT SUM(I2.item_cantidad)
	    FROM Producto P2
	    JOIN Item_Factura I2 ON P2.prod_codigo = I2.item_producto
        JOIN Factura F2 ON I2.item_tipo + I2.item_sucursal + I2.item_numero = F2.fact_tipo + F2.fact_sucursal + F2.fact_numero  
        WHERE MONTH(F1.fact_fecha) = MONTH(F2.fact_fecha) 
		AND YEAR(F1.fact_fecha) = YEAR(F2.fact_fecha)-1 AND P2.prod_codigo = P1.prod_codigo),0)as cant_ventas_mes_anterior,
	   COUNT(fact_tipo + fact_sucursal + fact_numero)as cant_facturas 
FROM Producto P1
JOIN Item_Factura I1 ON P1.prod_codigo = I1.item_producto
JOIN Factura F1 ON I1.item_tipo + I1.item_sucursal + I1.item_numero = F1.fact_tipo + F1.fact_sucursal + F1.fact_numero
GROUP BY prod_codigo, prod_detalle, MONTH(F1.fact_fecha), YEAR(F1.fact_fecha)
ORDER BY MONTH(F1.fact_fecha),YEAR(F1.fact_fecha), P1.prod_codigo

--18 ✔
SELECT rubr_detalle, SUM(item_cantidad *item_precio) as ventas, prod_codigo AS prod_mas_vendido,  
      (SELECT TOP 1 item_producto
        FROM Item_Factura
        JOIN Producto P2 ON P2.prod_codigo = item_producto
	    WHERE P2.prod_rubro = rubr_id AND item_producto <> (SELECT TOP 1 item_producto
                                                           FROM Item_Factura
                                                           JOIN Producto ON prod_codigo = item_producto
	                                                       WHERE rubr_id = prod_rubro
                                                           GROUP BY item_producto
                                                           ORDER BY SUM(item_cantidad*item_precio) DESC)
	   GROUP BY item_producto
	   ORDER BY SUM(item_cantidad*item_precio)DESC) AS prod2_mas_vendido,
	   (SELECT TOP 1 fact_cliente FROM Factura JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero 
	    WHERE item_producto in (select prod_codigo from Producto where prod_rubro = rubr_id) GROUP BY fact_cliente ORDER BY SUM(item_precio * item_cantidad) DESC) as cliente_mas_compro
FROM Rubro
JOIN Producto ON prod_rubro = rubr_id
JOIN Item_Factura ON prod_codigo = item_producto
WHERE prod_codigo in (SELECT TOP 1 item_producto
        FROM Item_Factura
        JOIN Producto ON prod_codigo = item_producto
	    WHERE rubr_id = prod_rubro
        GROUP BY item_producto
        ORDER BY SUM(item_cantidad*item_precio) DESC)
GROUP BY rubr_detalle, rubr_id, prod_codigo
ORDER BY COUNT(DISTINCT item_producto)

SELECT P2.prod_detalle, SUM(I2.item_cantidad)
        FROM Producto P2
        JOIN Item_Factura I2 ON P2.prod_codigo = I2.item_producto
        GROUP BY P2.prod_detalle
        ORDER BY SUM(I2.item_cantidad) DESC
  
--19 ✔
SELECT P1.prod_codigo, P1.prod_detalle, P1.prod_familia, F1.fami_detalle,
       (SELECT TOP 1 F2.fami_detalle
	    FROM Familia F2
		WHERE LEFT(F2.fami_detalle,5) = LEFT(P1.prod_detalle,5)
		GROUP BY F2.fami_detalle
		ORDER BY COUNT(*) DESC, F2.fami_detalle ASC) as familia_sugerida,
		(SELECT TOP 1 F2.fami_id
	    FROM Familia F2
		WHERE LEFT(F2.fami_detalle,5) = LEFT(P1.prod_detalle,5)
		GROUP BY F2.fami_id, F2.fami_detalle
		ORDER BY COUNT(*) DESC, F2.fami_detalle ASC) as familia_sugerida
FROM Producto P1
JOIN Familia F1 ON F1.fami_id = P1.prod_familia
WHERE F1.fami_detalle <> (SELECT TOP 1 F2.fami_detalle
	                      FROM Familia F2
		                  WHERE LEFT(F2.fami_detalle,5) = LEFT(P1.prod_detalle,5)
		                  GROUP BY F2.fami_detalle, F2.fami_id
		                  ORDER BY COUNT(*) DESC, F2.fami_detalle ASC)

--20 ✔
SELECT E1.empl_codigo, E1.empl_nombre, E1.empl_apellido, YEAR(E1.empl_ingreso) as año_ingreso,
       (CASE WHEN (SELECT COUNT(*) FROM Factura WHERE fact_vendedor = E1.empl_codigo AND YEAR(fact_fecha) = 2011) >= 50 
	    THEN (SELECT COUNT(*) FROM Factura WHERE fact_total > 100 AND fact_vendedor = E1.empl_codigo AND YEAR(fact_fecha) = 2011)
		ELSE (SELECT COUNT(*) * 0.5 FROM Factura
		      --JOIN Empleado E2 ON E2.empl_jefe = E1.empl_codigo  
			  WHERE YEAR(fact_fecha) = 2011 and fact_vendedor IN (SELECT E2.empl_codigo FROM Empleado E2 WHERE E2.empl_jefe = E1.empl_codigo))
		END) as puntaje_2011,
		(CASE WHEN (SELECT COUNT(*) FROM Factura WHERE fact_vendedor = E1.empl_codigo AND YEAR(fact_fecha) = 2012) >= 50 
	    THEN (SELECT COUNT(*) FROM Factura WHERE fact_total > 100 AND fact_vendedor = E1.empl_codigo AND YEAR(fact_fecha) = 2012)
		ELSE (SELECT COUNT(*) * 0.5 FROM Factura
		      --JOIN Empleado E2 ON E2.empl_jefe = E1.empl_codigo  
			  WHERE YEAR(fact_fecha) = 2012 and fact_vendedor IN (SELECT E2.empl_codigo FROM Empleado E2 WHERE E2.empl_jefe = E1.empl_codigo))
		END) as puntaje_2012
FROM Empleado E1
ORDER BY puntaje_2012 DESC


--21 ✔
SELECT YEAR(fact_fecha), COUNT(DISTINCT fact_cliente) as clientes_mal_facturados, 
       COUNT(DISTINCT (fact_tipo + fact_sucursal + fact_numero)) as facturas_mal_realizadas
FROM Factura
JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
GROUP BY YEAR(fact_fecha)
HAVING SUM(fact_total - fact_total_impuestos) - SUM(item_precio*item_cantidad) > 1
/*
WHERE (F.fact_total-F.fact_total_impuestos) NOT BETWEEN (
												SELECT SUM(item_cantidad * item_precio)-1
												FROM Item_Factura
												WHERE item_numero+item_sucursal+item_tipo = F.fact_numero+F.fact_sucursal+F.fact_tipo
												)
												AND
												(
												SELECT SUM(item_cantidad * item_precio)+1
												FROM Item_Factura
												WHERE item_numero+item_sucursal+item_tipo = F.fact_numero+F.fact_sucursal+F.fact_tipo
												)
*/

--22 ✔
SELECT R.rubr_detalle
	,CASE
	    WHEN MONTH(F.fact_fecha) = 1 OR MONTH(F.fact_fecha) = 2 OR MONTH(F.fact_fecha) = 3 THEN 1
		WHEN MONTH(F.fact_fecha) = 4 OR MONTH(F.fact_fecha) = 5 OR MONTH(F.fact_fecha) = 6 THEN 2
		WHEN MONTH(F.fact_fecha) = 7 OR MONTH(F.fact_fecha) = 8 OR MONTH(F.fact_fecha) = 9 THEN 3
        ELSE 4
	 END AS [Trimestre]
	,COUNT(DISTINCT F.fact_tipo+F.fact_numero+F.fact_sucursal) [Cantidad de facturas emitidas]
	,COUNT(DISTINCT IFACT.item_producto)
	,YEAR(F.fact_fecha)
FROM Rubro R
JOIN Producto P ON P.prod_rubro = R.rubr_id
JOIN Item_Factura IFACT ON IFACT.item_producto = P.prod_codigo
JOIN Factura F ON IFACT.item_numero = F.fact_numero AND IFACT.item_sucursal = F.fact_sucursal AND IFACT.item_tipo = F.fact_tipo
WHERE P.prod_codigo NOT IN (SELECT comp_producto FROM Composicion)
GROUP BY R.rubr_detalle ,CASE
		                     WHEN MONTH(F.fact_fecha) = 1 OR MONTH(F.fact_fecha) = 2 OR MONTH(F.fact_fecha) = 3 THEN 1
		                     WHEN MONTH(F.fact_fecha) = 4 OR MONTH(F.fact_fecha) = 5 OR MONTH(F.fact_fecha) = 6 THEN 2
		                     WHEN MONTH(F.fact_fecha) = 7 OR MONTH(F.fact_fecha) = 8 OR MONTH(F.fact_fecha) = 9 THEN 3
                             ELSE 4
	                     END,
	YEAR(F.fact_fecha)--MONTH(F.fact_fecha)
HAVING COUNT(DISTINCT F.fact_tipo+F.fact_numero+F.fact_sucursal) > 100
ORDER BY 1,3 DESC

--23 ✔ revisar comentario
SELECT YEAR(F.fact_fecha) AS año, C.comp_producto, COUNT(DISTINCT comp_componente) AS cant_componentes,
       COUNT(DISTINCT F.fact_numero+F.fact_sucursal+F.fact_tipo) AS cant_facturas,
       (SELECT TOP 1 fact_cliente
	    FROM Composicion
        JOIN Item_Factura ON item_producto = comp_producto
        JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo 
		WHERE YEAR(F.fact_fecha) = YEAR(fact_fecha) AND comp_producto = C.comp_producto
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC) as cliente_mas_compro,
		((SELECT SUM(item_cantidad * item_precio) *100 FROM Factura --si aca sumo directamente da cualquier cosa
		  JOIN Item_Factura ON item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
		  WHERE YEAR(F.fact_fecha) =  YEAR(fact_fecha) AND item_producto = C.comp_producto) / 
		  (SELECT SUM(fact_total) FROM Factura
		  WHERE YEAR(F.fact_fecha) =  YEAR(fact_fecha))) AS porcentaje_ventas_total
FROM Composicion C
JOIN Item_Factura I ON I.item_producto = C.comp_producto
JOIN Factura F ON F.fact_numero+F.fact_sucursal+F.fact_tipo = I.item_numero+I.item_sucursal+I.item_tipo
WHERE comp_producto = (SELECT TOP 1 comp_producto FROM Composicion
                       JOIN Item_Factura ON item_producto = comp_producto
                       JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo 
					   WHERE YEAR(F.fact_fecha) = YEAR(fact_fecha)
					   GROUP BY comp_producto
					   ORDER BY SUM(item_cantidad) DESC)
GROUP BY YEAR(F.fact_fecha), C.comp_producto

--24 ✔
SELECT P.prod_codigo, P.prod_detalle, SUM(I.item_cantidad)
FROM Producto P
JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero+F.fact_sucursal+F.fact_tipo = I.item_numero+I.item_sucursal+I.item_tipo
WHERE F.fact_vendedor in (SELECT TOP 2 empl_codigo FROM Empleado
                          ORDER BY empl_comision DESC)
	  AND P.prod_codigo in (SELECT comp_producto FROM Composicion)					   
GROUP BY P.prod_codigo, P.prod_detalle
HAVING COUNT(I.item_producto) > 5
ORDER BY 3 DESC

--25 ✔
SELECT YEAR(F.fact_fecha) as año, Fam.fami_id,
       COUNT(DISTINCT prod_rubro) as cant_rubros,
	   (SELECT COUNT(DISTINCT comp_componente) FROM Producto JOIN Composicion ON comp_producto = prod_codigo WHERE prod_familia = Fam.fami_id) as cant_componentes,
	   (SELECT COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) FROM Producto
       JOIN Item_Factura ON item_producto = prod_codigo
       JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo 
       WHERE prod_familia = Fam.fami_id AND YEAR(fact_fecha) = YEAR(F.fact_fecha) ) as cant_facturas,
	   (SELECT TOP 1 fact_cliente FROM Producto
       JOIN Item_Factura ON item_producto = prod_codigo
       JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo 
       WHERE prod_familia = Fam.fami_id AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
	   GROUP BY fact_cliente
	   ORDER BY SUM(fact_total) DESC) as cliente_mas_compro
FROM Producto P
JOIN Familia Fam ON Fam.fami_id = P.prod_familia
JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero+F.fact_sucursal+F.fact_tipo = I.item_numero+I.item_sucursal+I.item_tipo 
WHERE Fam.fami_id = (SELECT TOP 1 prod_familia FROM Producto
                        JOIN Item_Factura ON item_producto = prod_codigo
                        JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
						WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
						GROUP BY prod_familia
						ORDER BY SUM(item_cantidad) DESC)
GROUP BY YEAR(F.fact_fecha), Fam.fami_id
ORDER BY SUM(F.fact_total) DESC, 2

--26 ✔
SELECT E.empl_codigo, E.empl_apellido, COUNT(DISTINCT depo_codigo) as depositos_acargo, 
       (SELECT TOP 1 SUM(fact_total) FROM Factura F1
	   WHERE F1.fact_vendedor = E.empl_codigo AND YEAR(F1.fact_fecha) = 2012) as monto_total_facturado, 
      (SELECT TOP 1 fact_cliente FROM Factura F1
	   WHERE F1.fact_vendedor = E.empl_codigo AND YEAR(F1.fact_fecha) = 2012
	   GROUP BY fact_cliente
	   ORDER BY SUM(fact_total) DESC) as cliente_mas_vendio,
	  (SELECT TOP 1 item_producto FROM Item_Factura I1
	   JOIN Factura F1 ON F1.fact_tipo + F1.fact_sucursal + F1.fact_numero = I1.item_tipo + I1.item_sucursal + I1.item_numero
	   WHERE F1.fact_vendedor = E.empl_codigo AND YEAR(F1.fact_fecha) = 2012
	   GROUP BY item_producto
	   ORDER BY SUM(item_cantidad) DESC) as producto_mas_vendido,
	   ( ((SELECT SUM(fact_total) FROM Factura F1 WHERE YEAR(F1.fact_fecha) = 2012 AND F1.fact_vendedor = E.empl_codigo) * 100) 
	      / (SELECT SUM(fact_total) FROM Factura F1 WHERE YEAR(F1.fact_fecha) = 2012) )
FROM Empleado E
LEFT JOIN DEPOSITO ON depo_encargado = E.empl_codigo
LEFT JOIN Factura F1 ON F1.fact_vendedor = E.empl_codigo
WHERE YEAR(F1.fact_fecha) = 2012
GROUP BY E.empl_apellido, E.empl_codigo
ORDER BY (SELECT TOP 1 SUM(fact_total) FROM Factura F1
	    WHERE F1.fact_vendedor = E.empl_codigo AND YEAR(F1.fact_fecha) = 2012) DESC

--27 ✔
SELECT YEAR(F.fact_fecha) as año, P.prod_envase, E.enva_detalle, COUNT(DISTINCT P.prod_codigo) as cant_prod, 
       COUNT(DISTINCT I.item_producto) as cant_prod_facturados,
       (SELECT TOP 1 prod_codigo FROM Producto
	    JOIN Item_Factura ON item_producto = prod_codigo
        JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo 
		WHERE prod_envase = P.prod_envase AND YEAR(F.fact_fecha) = YEAR(fact_fecha)
		GROUP BY prod_codigo
		ORDER BY SUM(item_cantidad) DESC) as prod_mas_vendido,
	   SUM(I.item_cantidad * I.item_precio) as monto_total,
	   ( ((SUM(I.item_cantidad * I.item_precio))*100) / (SELECT SUM(item_cantidad * item_precio) FROM Producto
	                                                     JOIN Item_Factura ON item_producto = prod_codigo
                                                         JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo 
		                                                 WHERE YEAR(F.fact_fecha) = YEAR(fact_fecha)) ) as porcentaje
FROM Producto P 
JOIN Envases E ON E.enva_codigo = P.prod_envase 
RIGHT JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero+F.fact_sucursal+F.fact_tipo = I.item_numero+I.item_sucursal+I.item_tipo
GROUP BY YEAR(F.fact_fecha), P.prod_envase, E.enva_detalle
ORDER BY 1, 7 DESC


--28 ✔
SELECT YEAR(fact_fecha), empl_codigo, empl_apellido, COUNT(DISTINCT (F1.fact_sucursal+F1.fact_numero+F1.fact_tipo)) as cant_facturas,
       COUNT(DISTINCT F1.fact_cliente) as cant_clientes,  
		
		(SELECT COUNT(DISTINCT I1.item_producto) FROM Composicion
	    JOIN Item_Factura I1 ON I1.item_producto = comp_producto
		JOIN Factura F2 ON F2.fact_tipo + F2.fact_sucursal + F2.fact_numero = I1.item_tipo + I1.item_sucursal + I1.item_numero
	    WHERE F1.fact_vendedor = F2.fact_vendedor) as cant_productos_comp,

		(SELECT COUNT(DISTINCT I1.item_producto) FROM Producto
	    JOIN Item_Factura I1 ON I1.item_producto = prod_codigo
		JOIN Factura F2 ON F2.fact_tipo + F2.fact_sucursal + F2.fact_numero = I1.item_tipo + I1.item_sucursal + I1.item_numero
	    WHERE F1.fact_vendedor = F2.fact_vendedor and I1.item_producto not in(SELECT comp_producto FROM Composicion) AND YEAR(F1.fact_fecha) = YEAR(F2.fact_fecha)) as cant_productos,
	   
	   SUM(F1.fact_total) as monto_total
FROM Empleado
RIGTH JOIN Factura F1 ON F1.fact_vendedor = empl_codigo
GROUP BY empl_codigo, empl_apellido, fact_vendedor, YEAR(fact_fecha)
ORDER BY 1 DESC, (SELECT COUNT(DISTINCT prod_codigo) FROM Producto
				  JOIN Item_Factura ON item_producto = prod_codigo
				  JOIN Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
				  WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha) AND fact_vendedor = F1.fact_vendedor) DESC 

--29  ✔
SELECT P.prod_codigo, P.prod_detalle, SUM(I.item_cantidad) AS cant_vendida,
       COUNT(DISTINCT I.item_numero+I.item_sucursal+I.item_sucursal) as cant_facturas,
	   SUM(I.item_cantidad*I.item_precio) as monto_total
FROM Producto P
JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero+F.fact_sucursal+F.fact_tipo = I.item_numero+I.item_sucursal+I.item_tipo
WHERE YEAR(F.fact_fecha) = 2011 AND P.prod_familia in (SELECT fami_id FROM Familia
                                                    JOIN Producto ON prod_familia = fami_id
					                                GROUP BY fami_id
					                                HAVING  COUNT(DISTINCT prod_codigo) > 20)
GROUP BY P.prod_codigo, P.prod_detalle
ORDER BY 3 DESC

--30 ✔
SELECT J.empl_nombre, COUNT(DISTINCT E.empl_codigo) as cant_empl,
       SUM(F.fact_total) as monto_total, COUNT(DISTINCT F.fact_numero+F.fact_sucursal+F.fact_tipo) as cant_facturas,
	   (SELECT TOP 1 empl_nombre FROM Empleado
	    JOIN Factura ON fact_vendedor = empl_codigo
		WHERE YEAR(fact_fecha) = 2012 and empl_jefe = J.empl_codigo
		GROUP BY empl_nombre
		ORDER BY SUM(fact_total) DESC) as mejor_empleado
FROM Empleado J
JOIN Empleado E ON E.empl_jefe = J.empl_codigo
JOIN Factura F ON F.fact_vendedor = E.empl_codigo
WHERE YEAR(F.fact_fecha) = 2012
GROUP BY J.empl_nombre, J.empl_codigo 
HAVING COUNT(DISTINCT  F.fact_numero+F.fact_sucursal+F.fact_tipo) > 10
ORDER BY SUM(F.fact_total) DESC


--31 ✔ se complica los subselect a la hora de agrupar
SELECT YEAR(F.fact_fecha), E.empl_codigo, E.empl_nombre, E.empl_apellido,
       COUNT(DISTINCT F.fact_numero+F.fact_sucursal+F.fact_tipo) as cant_facturas,
	   COUNT(DISTINCT F.fact_cliente) as cant_clientes,
	   (SELECT COUNT(DISTINCT prod_codigo) FROM Producto 
	    JOIN Item_Factura ON prod_codigo = item_producto
		JOIN Factura ON item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
		WHERE prod_codigo not in (SELECT comp_producto FROM Composicion) 
		      AND F.fact_vendedor = E.empl_codigo AND YEAR(F.fact_fecha) = YEAR(fact_fecha)) as cant_productos,
	   (SELECT COUNT(DISTINCT comp_producto) FROM Composicion
	    JOIN Item_Factura ON comp_producto = item_producto 
		JOIN Factura ON item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo 
		WHERE fact_vendedor = E.empl_codigo AND YEAR(F.fact_fecha) = YEAR(fact_fecha)) as cant_productos_comp,
		SUM(F.fact_total) as monto_total_vendido
FROM Empleado E
JOIN Factura F ON F.fact_vendedor = E.empl_codigo
JOIN Item_Factura I ON I.item_numero+I.item_sucursal+I.item_tipo = F.fact_numero+F.fact_sucursal+F.fact_tipo
GROUP BY YEAR(F.fact_fecha), E.empl_codigo, E.empl_nombre, E.empl_apellido, F.fact_vendedor
ORDER BY 1 DESC, COUNT(DISTINCT I.item_producto) DESC

--32 ✔
SELECT F1.fami_id, F1.fami_detalle, F2.fami_id, F2.fami_detalle, 
       COUNT(DISTINCT I1.item_numero+I1.item_sucursal+I1.item_tipo) as cant_facturas,
	   SUM(I1.item_precio * I1.item_cantidad) + SUM(I2.item_precio * I2.item_cantidad) as total_vendido
FROM Familia F1
JOIN Producto P1 ON P1.prod_familia = F1.fami_id
JOIN Item_Factura I1 ON I1.item_producto = P1.prod_codigo,
     Familia F2
JOIN Producto P2 ON P2.prod_familia = F2.fami_id
JOIN Item_Factura I2 ON I2.item_producto = P2.prod_codigo
WHERE F1.fami_id < F2.fami_id AND I1.item_numero+I1.item_sucursal+I1.item_tipo = I2.item_numero+I2.item_sucursal+I2.item_tipo
GROUP BY F1.fami_id, F1.fami_detalle, F2.fami_id, F2.fami_detalle
HAVING COUNT(DISTINCT I1.item_numero+I1.item_sucursal+I1.item_tipo) > 10
ORDER BY 6

--33 ✔
SELECT C.comp_componente, P.prod_detalle, SUM(I.item_cantidad) as cant_venida, 
       COUNT(DISTINCT F.fact_numero+F.fact_sucursal+F.fact_tipo) as cant_fact,
	   AVG(I.item_precio*I.item_cantidad) as precio_promedio,
	   SUM(I.item_cantidad * I.item_precio)
FROM Composicion C
JOIN Item_Factura I ON I.item_producto = C.comp_componente
JOIN Producto P ON P.prod_codigo = C.comp_componente 
JOIN Factura F ON F.fact_numero+F.fact_sucursal+F.fact_tipo = I.item_numero+I.item_sucursal+I.item_tipo
WHERE C.comp_producto = (SELECT TOP 1 item_producto FROM Item_Factura
						 JOIN Factura ON fact_numero = item_numero AND fact_tipo = item_tipo AND fact_sucursal = item_sucursal
						 WHERE item_producto IN (SELECT comp_producto FROM Composicion) AND YEAR(fact_fecha) = 2012
						 GROUP BY item_producto
						 ORDER BY SUM(item_cantidad) DESC)
GROUP BY C.comp_componente, P.prod_detalle

--34 
SELECT R.rubr_id, R.rubr_detalle, MONTH(fact_fecha) as mes, 
       CASE WHEN (SELECT COUNT(DISTINCT prod_rubro) FROM Rubro
	             JOIN Producto ON prod_rubro = rubr_id
		         JOIN Item_Factura ON item_numero+item_tipo+item_sucursal = I1.item_numero+I1.item_tipo+I1.item_sucursal
				 --JOIN Factura ON item_numero+item_tipo+item_sucursal = fact_numero+fact_sucursal+fact_tipo
				 --WHERE item_numero+item_tipo+item_sucursal = I1.item_numero+I1.item_tipo+I1.item_sucursal--prod_rubro = R.rubr_id AND MONTH(F1.fact_fecha)= MONTH(fact_fecha) AND YEAR(fact_fecha) = 2011
				 ) > 1
	   THEN (SELECT COUNT(DISTINCT prod_rubro) FROM Rubro
				 JOIN Producto ON prod_rubro = rubr_id
		         JOIN Item_Factura ON item_numero+item_tipo+item_sucursal = I1.item_numero+I1.item_tipo+I1.item_sucursal
				 --JOIN Factura ON item_numero+item_tipo+item_sucursal = fact_numero+fact_sucursal+fact_tipo
				 --WHERE item_numero+item_tipo+item_sucursal = I1.item_numero+I1.item_tipo+I1.item_sucursal--prod_rubro = R.rubr_id AND MONTH(F1.fact_fecha)= MONTH(fact_fecha) AND YEAR(fact_fecha) = 2011
				 )
	   ELSE 0
	   END as fact_mal_realizadas
FROM RUBRO R
LEFT JOIN Producto P1 ON P1.prod_rubro = rubr_id
JOIN Item_Factura I1 ON I1.item_producto = P1.prod_codigo
JOIN Factura F1 ON F1.fact_numero+F1.fact_tipo+F1.fact_sucursal = I1.item_numero+I1.item_tipo+I1.item_sucursal
WHERE YEAR(F1.fact_fecha) = 2011
GROUP BY R.rubr_id, R.rubr_detalle, MONTH(F1.fact_fecha)
ORDER BY 4 DESC

SELECT rubr_id, rubr_detalle, MONTH(fact_fecha) as mes, 
       COUNT(DISTINCT (fact_numero+fact_tipo+fact_sucursal))
FROM RUBRO
JOIN Producto ON prod_rubro = rubr_id
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
WHERE YEAR(fact_fecha) = 2011 AND (fact_numero+fact_tipo+fact_sucursal) in (SELECT (F1.fact_numero+F1.fact_tipo+F1.fact_sucursal) FROM Factura F1
                                                                            JOIN Item_Factura I1 ON F1.fact_numero+F1.fact_tipo+F1.fact_sucursal = I1.item_numero+I1.item_tipo+I1.item_sucursal
																			JOIN Producto P1 ON P1.prod_codigo = I1.item_producto
																			WHERE YEAR(F1.fact_fecha) = 2011
                                                                            GROUP BY (F1.fact_numero+F1.fact_tipo+F1.fact_sucursal)
																			HAVING COUNT(DISTINCT prod_rubro) > 1)
GROUP BY rubr_id, rubr_detalle, MONTH(fact_fecha)  
ORDER BY 4 DESC

--35 ✔
SELECT YEAR(F1.fact_fecha) as año,  P1.prod_codigo,  P1.prod_detalle, COUNT(DISTINCT F1.fact_numero+F1.fact_tipo+F1.fact_sucursal) as cant_fact,
       COUNT(DISTINCT F1.fact_cliente) as cant_clientes, (SELECT COUNT(*) FROM Composicion WHERE comp_producto =  P1.prod_codigo) as cant_comp,
	   ( (SUM(I1.item_precio * I1.item_cantidad) * 100) / (SELECT SUM(item_precio * item_cantidad) FROM Item_Factura
	                                                 JOIN Factura ON fact_numero+fact_tipo+fact_sucursal = item_numero+item_tipo+item_sucursal
													 WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha) ) ) as porcentaje_venta_total
FROM Producto P1
JOIN Item_Factura I1 ON I1.item_producto = P1.prod_codigo
JOIN Factura F1 ON F1.fact_numero+F1.fact_tipo+F1.fact_sucursal = I1.item_numero+I1.item_tipo+I1.item_sucursal
GROUP BY YEAR(F1.fact_fecha),  P1.prod_codigo,  P1.prod_detalle
ORDER BY 1, SUM(I1.item_cantidad)


--Ejercicio de parcial del 1C2020
--Realizar una consulta SQL que retorne el stock de los productos pero exponiendo una posible composición de sus componentes.
--Ejemplo: Si en el stock tengo 1 hamburguesa, 1 papa y gaseosas, y suponemos que esta configuración es combo 1, el query deberá devolver Combo 1 , cantidad 1.
--Nota: No se permiten sub select en el FROM.

SELECT P1.prod_codigo, P1.prod_detalle, 
       CASE WHEN((SELECT COUNT(*) FROM Composicion
	              WHERE comp_producto = P1.prod_codigo)  = 0)
	   THEN SUM(stoc_cantidad) 
	   ELSE (SELECT TOP 1 (SUM(stoc_cantidad)/comp_cantidad) FROM Composicion
	         JOIN STOCK ON stoc_producto = comp_componente
	         WHERE comp_producto = P1.prod_codigo 
		     GROUP BY comp_componente, comp_cantidad
			 ORDER BY 1)
	   END
FROM Producto P1
JOIN STOCK ON stoc_producto = P1.prod_codigo
GROUP BY P1.prod_codigo, P1.prod_detalle
order by P1.prod_detalle

--Ejercicio de parcial del 1C2020
--Mostrar las zonas donde menor cantidad de ventas se están realizando en el año actual. 
--Recordar que un empleado está puesto como fact_vendedor en factura. 
--De aquellas zonas donde menores ventas tengamos, se deberá mostrar (cantidad de clientes distintos que operan en esa zona), 
--cantidad de clientes que aparte de ese zona, compran en otras zonas (es decir, a otros vendedores de la zona). 
--El resultado se deberá mostrar por cantidad de productos vendidos en la zona en cuestión de manera descendiente.
--Nota: No se puede usar select en el from.

SELECT Z.zona_codigo, Z.zona_detalle, COUNT(DISTINCT F.fact_cliente),
       (SELECT COUNT(DISTINCT clie_codigo) FROM Cliente
	   JOIN Factura ON fact_cliente = clie_codigo
	   JOIN Empleado ON empl_codigo = fact_vendedor
	   JOIN Departamento ON depa_codigo = empl_departamento
	   JOIN Zona ON zona_codigo = depa_zona
	   WHERE zona_codigo <> Z.zona_codigo AND clie_codigo in (SELECT fact_cliente FROM Factura
	                                                          JOIN Empleado ON empl_codigo = fact_vendedor
	                                                          JOIN Departamento ON depa_codigo = empl_departamento
	                                                          JOIN Zona ON zona_codigo = depa_zona
															  WHERE zona_codigo = Z.zona_codigo))
FROM Zona Z
JOIN Departamento D ON D.depa_zona = Z.zona_codigo
JOIN Empleado E ON E.empl_departamento = D.depa_codigo
LEFT JOIN Factura F ON F.fact_vendedor = E.empl_codigo
LEFT JOIN Item_Factura I ON I.item_numero+I.item_sucursal+I.item_tipo = F.fact_numero+F.fact_sucursal+F.fact_tipo
GROUP BY Z.zona_detalle, Z.zona_codigo
ORDER BY SUM(I.item_cantidad)


--Ejercicio que me tomaron en el parcial
--Con el fin de analizar el posicionamiento de ciertos productos se necesita mostrar solo los 5 rubros de productos más vendidos y además, 
--por cada uno de estos rubros  saber cuál es el producto más exitoso (es decir, con más ventas) y si el mismo es “simple” o “compuesto”. 
--Por otro lado, se pide se indique si hay “stock disponible” o si hay “faltante” para afrontar las ventas del próximo mes. 
--Considerar que se estima que la venta aumente un 10% respecto del mes de diciembre del año pasado.
--Armar una consulta SQL que retorne esta información.

SELECT TOP 5  R.rubr_id, 
             (SELECT SUM(item_cantidad) FROM Rubro
             JOIN Producto ON prod_rubro = P.prod_rubro
			 JOIN Item_Factura ON item_producto = prod_codigo) AS cant_vendida,
             P.prod_detalle,
			 CASE WHEN(SELECT COUNT(*) FROM Composicion WHERE comp_producto = P.prod_codigo) = 0
			 THEN 'simple'
			 ELSE 'compuesto'
			 END,
			 CASE WHEN(SELECT SUM(stoc_cantidad)* 1.1 FROM STOCK
			           WHERE stoc_producto = prod_codigo) > (SELECT SUM(item_cantidad) FROM Item_Factura
					                                         JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
															 WHERE item_producto = P.prod_codigo AND YEAR(fact_fecha) = 2012 AND MONTH(fact_fecha) = 12)
			 THEN 'stock disponible'
			 ELSE 'faltante'
			 END
FROM Rubro R 				  			  	   
JOIN Producto P ON P.prod_rubro = R.rubr_id
JOIN Item_Factura I ON I.item_producto = P.prod_codigo
JOIN Factura F ON F.fact_numero+F.fact_sucursal+F.fact_tipo = I.item_numero+I.item_sucursal+I.item_tipo
WHERE R.rubr_id in (SELECT TOP 1 rubr_detalle FROM Rubro
                    JOIN Producto ON prod_rubro = rubr_id
					JOIN Item_Factura ON item_producto = prod_codigo
					GROUP BY rubr_id
					ORDER BY SUM(item_cantidad))
GROUP BY P.prod_rubro, P.prod_detalle, P.prod_codigo 
ORDER BY SUM(I.item_cantidad) DESC