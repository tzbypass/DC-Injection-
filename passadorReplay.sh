#!/bin/bash


REPLAY_SRC="/sdcard/Download"
PKG="com.dts.freefireth"
FF_SELECIONADO="Free Fire Normal"
DST_DIR="/sdcard/Android/data/com.dts.freefireth/files/MReplays"
CONN_PORT=""
USUARIO="N/A"
VALIDADE_USER="N/A"
ADB_STATUS="Desconectado"
APK_VER=""
NC='\033[0m'
AZUL='\033[1;34m'
VERDE='\033[1;32m'
VERMELHO='\033[1;31m'
AMARELO='\033[1;33m'
CIANO='\033[1;36m'
conectar_adb() {
clear
echo "╔════════════════════════════════════╗"
echo "║    PASSO 1: CONECTAR ADB           ║"
echo "╚════════════════════════════════════╝"
echo ""
if adb devices 2>/dev/null | grep -q "device$"; then
echo -e "${VERDE}✅ ADB já conectado${NC}"
sleep 1
return
fi
read -rp "Porta de pareamento: " PAIR_PORT
read -rp "Código de pareamento: " PAIR_CODE
printf '%s\n' "$PAIR_CODE" | adb pair "localhost:$PAIR_PORT" || exit 1
read -rp "Porta de conexão: " CONN_PORT
adb connect "localhost:$CONN_PORT" || exit 1
if adb devices | grep -q "device$"; then
echo -e "${VERDE}✅ ADB conectado com sucesso!${NC}"
else
echo -e "${VERMELHO}❌ Falha ao conectar ADB${NC}"
exit 1
fi
sleep 1
}
escolher_ff() {
clear
echo "╔════════════════════════════════════╗"
echo "║    PASSO 3: ESCOLHER FREE FIRE     ║"
echo "╚════════════════════════════════════╝"
echo ""
echo "1) Free Fire Normal"
echo "2) Free Fire MAX"
echo ""
while true; do
read -rp "Opção (1/2): " OP
case "$OP" in
1)
PKG="com.dts.freefireth"
FF_SELECIONADO="Free Fire Normal"
break
;;
2)
PKG="com.dts.freefiremax"
FF_SELECIONADO="Free Fire MAX"
break
;;
*) echo -e "${VERMELHO}Opção inválida${NC}" ;;
esac
done
DST_DIR="/sdcard/Android/data/$PKG/files/MReplays"
APK_VER=$(adb shell dumpsys package "$PKG" 2>/dev/null | grep versionName | head -1 | sed 's/.*=//' | tr -d '\r')
echo -e "${VERDE}✅ Selecionado: $FF_SELECIONADO${NC}"
echo -e "${VERDE}✅ Versão: ${APK_VER:-Desconhecida}${NC}"
sleep 1
}
desativar_termux() {
adb shell pm disable-user --user 0 com.termux >/dev/null 2>&1
echo -e "${VERDE}✅ Termux desativado${NC}"
}
processar_replay() {
local BIN="$1"
local JSON="${BIN%.bin}.json"
clear
echo "╔════════════════════════════════════╗"
echo "║    ⚡ REPLAY DETECTADO!             ║"
echo "╚════════════════════════════════════╝"
echo ""
echo -e "${VERDE}Arquivo: $(basename "$BIN")${NC}"
if ! adb shell "[ -f '$JSON' ]" 2>/dev/null; then
echo -e "${VERMELHO}❌ ERRO: JSON não encontrado${NC}"
sleep 2
return 1
fi
local TS
TS=$(basename "$BIN" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}')
if [ -z "$TS" ]; then
echo -e "${VERMELHO}❌ ERRO: Timestamp inválido${NC}"
sleep 2
return 1
fi
echo ""
echo -e "${AZUL}══════════════════════════════════════${NC}"
echo -e "${CIANO}📅 DATA: ${AMARELO}${TS:0:10}${NC}"
echo -e "${CIANO}⏰ HORA: ${AMARELO}${TS:11:8}${NC}"
echo -e "${AZUL}══════════════════════════════════════${NC}"
echo ""
APK_VER=$(adb shell dumpsys package "$PKG" 2>/dev/null | grep -m1 versionName | sed 's/.*=//' | tr -d '\r')
if [ -n "$APK_VER" ]; then
adb shell "sed -i 's/\"Version\":\"[^\"]*\"/\"Version\":\"$APK_VER\"/g' \"$JSON\"" >/dev/null 2>&1
echo -e "${VERDE}✅ Versão corrigida: $APK_VER${NC}"
fi
adb shell "settings put global auto_time 0" >/dev/null 2>&1
adb shell "settings put global auto_time_zone 0" >/dev/null 2>&1
echo -e "${AZUL}📱 Abrindo configurações de data/hora...${NC}"
adb shell "am start -a android.settings.DATE_SETTINGS" >/dev/null 2>&1
echo ""
echo -e "${AMARELO}�� CELULAR ABERTO - AJUSTE DATA/HORA PARA:${NC}"
echo -e "   ${VERDE}${TS:0:10} ${TS:11:8}${NC}"
echo ""
echo -e "${CIANO}⏳ Assim que ajustar, vou esperar o segundo exato...${NC}"
sleep 3
echo ""
echo -e "${AZUL}Aguardando o segundo exato: $TS${NC}"
while :; do
NOW=$(adb shell date +%Y-%m-%d-%H-%M-%S 2>/dev/null | tr -d '\r')
printf "\r⏰ Atual: %s" "$NOW"
if [ "$NOW" = "$TS" ]; then
echo -e "\n${VERDE}✅ SEGUNDO EXATO!${NC}"
break
fi
sleep 0.2
done
adb shell "input keyevent KEYCODE_BACK" >/dev/null 2>&1
adb shell "input keyevent KEYCODE_BACK" >/dev/null 2>&1
adb shell "input keyevent KEYCODE_HOME" >/dev/null 2>&1
adb shell "mkdir -p '$DST_DIR'" >/dev/null 2>&1
local BIN_DST="$DST_DIR/$(basename "$BIN")"
local JSON_DST="$DST_DIR/$(basename "$JSON")"
echo "📁 Copiando arquivos..."
adb exec-out "cat '$BIN'" 2>/dev/null | adb shell "cat > '$BIN_DST'" 2>/dev/null
adb exec-out "cat '$JSON'" 2>/dev/null | adb shell "cat > '$JSON_DST'" 2>/dev/null
adb shell "settings put global auto_time 1" >/dev/null 2>&1
adb shell "settings put global auto_time_zone 1" >/dev/null 2>&1
adb shell "rm -f '$BIN' '$JSON'" >/dev/null 2>&1
echo -e "${VERDE}✅ REPLAY MOVIDO!${NC}"
desativar_termux
echo ""
echo -e "${VERDE}✅ CICLO CONCLUÍDO! Voltando ao monitoramento...${NC}"
sleep 2
}
loop_automatico() {
clear
echo "╔════════════════════════════════════╗"
echo "║    �� MONITORAMENTO AUTOMÁTICO     ║"
echo "╚════════════════════════════════════╝"
echo ""
echo -e "${VERDE}📁 Monitorando: $REPLAY_SRC${NC}"
echo -e "${VERDE}🎯 Destino: $DST_DIR${NC}"
echo -e "${VERDE}🔐 Bypass: OBRIGATÓRIO${NC}"
echo ""
echo -e "${CIANO}⏳ Escaneando a cada 2 segundos...${NC}"
echo -e "${AMARELO}⚠️  Para sair: Ctrl+C${NC}"
echo ""
sleep 2
declare -A PROCESSADOS=()
while true; do
if ! adb devices 2>/dev/null | grep -q "device$"; then
clear
echo -e "${VERMELHO}❌ ADB desconectado!${NC}"
echo -e "${AMARELO}Tentando reconectar...${NC}"
adb connect "localhost:$CONN_PORT" 2>/dev/null
sleep 3
clear
continue
fi
mapfile -t BINS < <(
adb shell "
for f in \"$REPLAY_SRC\"/*.bin; do
if [ -f \"\$f\" ]; then
j=\"\${f%.bin}.json\"
[ -f \"\$j\" ] && echo \"\$f\"
fi
done
" 2>/dev/null | tr -d '\r'
)
if [ ${#BINS[@]} -gt 0 ]; then
for BIN in "${BINS[@]}"; do
if [ -n "$BIN" ] && [ -z "${PROCESSADOS[$BIN]:-}" ]; then
PROCESSADOS["$BIN"]="1"
processar_replay "$BIN"
fi
done
else
echo -e "${AMARELO}[$(date '+%H:%M:%S')] Monitorando... (Ctrl+C)${NC}"
sleep 2
fi
done
}
main() {
clear
echo "╔════════════════════════════════════╗"
echo "║    REPLAY PASSER - DIRETO AO PONTO ║"
echo "║    �� BYPASS OBRIGATÓRIO            ║"
echo "╚════════════════════════════════════╝"
echo ""
conectar_adb
escolher_ff
loop_automatico
main
}