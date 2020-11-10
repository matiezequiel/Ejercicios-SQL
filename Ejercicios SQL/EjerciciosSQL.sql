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


--16 promedio de ventas??
SELECT clie_razon_social, COUNT(DISTINCT fact_total) 
FROM Cliente
JOIN Factura ON clie_codigo = fact_cliente
GROUP BY clie_razon_social
ORDER BY clie_domicilio 

SELECT MAX(item_cantidad)
FROM Item_Factura
JOIN Factura ON  item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
WHERE  YEAR(fact_fecha) = 2012

--17 algo esta mal en cant_ventas_mes_anterior
SELECT STR(YEAR(F1.fact_fecha)) + STR(MONTH(F1.fact_fecha)) as periodo ,P1.prod_codigo, P1.prod_detalle, 
       SUM(I1.item_cantidad) as cantidad_vendida, 
	   (SELECT SUM(I2.item_cantidad)
	           FROM Producto P2
			   JOIN Item_Factura I2 ON P2.prod_codigo = I2.item_producto
               JOIN Factura F2 ON I2.item_tipo + I2.item_sucursal + I2.item_numero = F2.fact_tipo + F2.fact_sucursal + F2.fact_numero  
               WHERE ( MONTH(F1.fact_fecha)-1 = MONTH(F2.fact_fecha) AND STR(YEAR(F1.fact_fecha)) = STR(YEAR(F2.fact_fecha)) ) ) as cant_ventas_mes_anterior,
	   COUNT(fact_tipo + fact_sucursal + fact_numero) as cant_facturas 
FROM Producto P1
JOIN Item_Factura I1 ON P1.prod_codigo = I1.item_producto
JOIN Factura F1 ON I1.item_tipo + I1.item_sucursal + I1.item_numero = F1.fact_tipo + F1.fact_sucursal + F1.fact_numero
GROUP BY fact_fecha, prod_codigo, prod_detalle

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

