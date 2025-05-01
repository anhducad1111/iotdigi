#ifndef HTML_CONTENT_H
#define HTML_CONTENT_H

const char INDEX_HTML[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>OLED Display Control</title>
    <style>
        body{text-align:center;font-family:Arial;margin:20px;user-select:none}
        .controls{display:flex;justify-content:center;align-items:center;gap:10px;margin-bottom:20px}
        .direction-controls{display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0}
        .direction-row{display:flex;gap:10px;justify-content:center}
        input{font-size:24px;padding:10px;width:120px;margin:10px;text-align:center}
        button{font-size:32px;width:60px;height:60px;background:#4CAF50;color:white;border:none;cursor:pointer;border-radius:50%;transition:all 0.2s ease}
        button:hover{background:#45a049;transform:scale(1.1)}
        button:active{background:#367c39;transform:scale(0.95)}
        #text-size{font-size:24px;margin:10px 0}
    </style>
</head>
<body>
    <h1>OLED Display Control</h1>
    <div class='controls'>
        <button onclick='change(-1)'>-</button>
        <input type='number' id='num' min='0' max='9999' value='%VALUE%' onchange='updateDisplay(this.value)'>
        <button onclick='change(1)'>+</button>
    </div>
    
    <div class='size-controls controls'>
        <button onclick='changeSize(-1)'>-</button>
        <div id='text-size'>Size: <span>4</span></div>
        <button onclick='changeSize(1)'>+</button>
    </div>
    
    <div class='direction-controls'>
        <div class='direction-row'>
            <button onclick='move(0, -1)'>↑</button>
        </div>
        <div class='direction-row'>
            <button onclick='move(-1, 0)'>←</button>
            <button onclick='move(1, 0)'>→</button>
        </div>
        <div class='direction-row'>
            <button onclick='move(0, 1)'>↓</button>
        </div>
    </div>

    <script>
        let textSize = 4;
        let xPos = 0;
        let yPos = 0;
        
        function change(delta){
            var i=document.getElementById('num'),
            n=parseInt(i.value)+delta;
            n>=0&&n<=9999&&(i.value=n,updateDisplay(n));
        }
        
        function updateDisplay(v){
            fetch('/display?num='+v+'&size='+textSize+'&x='+xPos+'&y='+yPos)
            .then(r=>console.log('Updated:',v))
            .catch(e=>console.error('Error:',e));
        }
        
        function changeSize(delta) {
            textSize = Math.max(1, Math.min(8, textSize + delta));
            document.querySelector('#text-size span').textContent = textSize;
            updateDisplay(document.getElementById('num').value);
        }
        
        function move(dx, dy) {
            xPos += dx;
            yPos += dy;
            updateDisplay(document.getElementById('num').value);
        }
        
        document.addEventListener('keydown',function(e){
            e.key==='ArrowUp'||e.key==='+'?change(1):
            e.key==='ArrowDown'||e.key==='-'&&change(-1)
        });
    </script>
</body>
</html>
)rawliteral";

#endif // HTML_CONTENT_H
