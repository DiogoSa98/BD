SELECT count(tipo)
FROM Sgif.tf_eventos_meios NATURAL JOIN Sgif.d_meio NATURAL JOIN Sgif.d_evento NATURAL JOIN Sgif.d_tempo
WHERE idEvento = 15
GROUP BY ROLLUP(tipo, ano, mes);