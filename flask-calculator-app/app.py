from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/calculate', methods=['POST'])
def calculate():
    if request.is_json:
        data = request.json
        num1 = data.get('num1')
        num2 = data.get('num2')
        operation = data.get('operation')
    else:
        num1 = request.form.get('num1')
        num2 = request.form.get('num2')
        operation = request.form.get('operation')

    if num1 is None or num2 is None or operation is None:
        return jsonify({'error': 'Missing parameters num1, num2, or operation'}), 400

    try:
        num1 = float(num1)
        num2 = float(num2)

        if operation == 'add':
            result = num1 + num2
        elif operation == 'subtract':
            result = num1 - num2
        elif operation == 'multiply':
            result = num1 * num2
        elif operation == 'divide':
            if num2 == 0:
                return jsonify({'error': 'Division by zero is not allowed'}), 400
            result = num1 / num2
        else:
            return jsonify({'error': 'Invalid operation'}), 400

        # return jsonify({'result': result}), 200
        return render_template('index.html', result=result, num1=num1, num2=num2, operation=operation)

    except ValueError:
        return jsonify({'error': 'Invalid input, please provide numeric values'}), 400

@app.route('/health')
def health():
    # Perform a test calculation to check if the endpoint is functioning properly
    try:
        # Provide valid input parameters for the test calculation
        response = app.test_client().post('/calculate', json={'num1': 1, 'num2': 1, 'operation': 'add'})
        if response.status_code == 200:
            return jsonify({'status': 'ok'}), 200
        else:
            return jsonify({'status': 'error', 'message': 'Unexpected response from /calculate endpoint'}), 500
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
