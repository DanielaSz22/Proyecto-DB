from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from decimal import Decimal

app = Flask(__name__)
CORS(app)  # Permitir solicitudes cross-origin

# Configuración de la base de datos
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'tu_password',
    'database': 'control_telefonia'
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

@app.route('/agregar_llamada', methods=['POST'])
def agregar_llamada():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        data = request.json
        cursor.callproc('sp_agregar_llamada', [
            data['linea'],
            data['tipo'],
            Decimal(str(data['duracion']))
        ])
        
        # Obtener el resultado del procedimiento almacenado
        for result in cursor.stored_results():
            mensaje = result.fetchone()[0]
            
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({"success": True, "mensaje": mensaje})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/info_linea/<int:linea_id>', methods=['GET'])
def info_linea(linea_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.callproc('sp_info_linea', [linea_id])
        
        for result in cursor.stored_results():
            info = result.fetchone()
            
        cursor.close()
        conn.close()
        
        return jsonify({"success": True, "data": info})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/info_consolidada', methods=['GET'])
def info_consolidada():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.callproc('sp_info_consolidada')
        
        for result in cursor.stored_results():
            info = result.fetchone()
            
        cursor.close()
        conn.close()
        
        return jsonify({"success": True, "data": info})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

@app.route('/reiniciar_lineas', methods=['POST'])
def reiniciar_lineas():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.callproc('sp_reiniciar_lineas')
        
        for result in cursor.stored_results():
            mensaje = result.fetchone()[0]
            
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({"success": True, "mensaje": mensaje})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
