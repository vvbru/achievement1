.include "m8def.inc"

;Присваиваем символические имена регистрам
.def temp = r16

//Константы
.equ fck = 7372800 //битрейт
.equ baud = 115200
.equ ubrr	= (fck/(baud*16))-1
.equ end_character = 0b00000000

//Таймеры
.equ timer0 = 0b00000101
.equ timer2 = 0b00000101

.equ TIMER1_INTERVAL = 0x00
.equ TIMER2_INTERVAL = 0x00

.dseg
.cseg
s
.org $000
rjmp res

.org $004
rjmp timer2_ovf

.org $009
rjmp timer0_ovf

res:
ldi temp, high(RAMEND)
out sph, temp
ldi temp, low(RAMEND)
out spl, temp

//Запись данных для отправки
ping_str: .db "PING", 0x0a, 0x0d, end_character
pong_str: .db "PONG", 0x0a, 0x0d, end_character

ldi	temp, HIGH(ubrr)
out	UBRRH,temp
ldi	temp, LOW(ubrr)	
out	UBRRL,temp
ldi	temp, (1<<TXEN)|(1<<RXEN)
out	UCSRB,temp
ldi temp, (1<<URSEL)|(1<<USBS)|(3<<UCSZ0)
out UCSRC, temp

//Включение поддержки глобального прерывания для таймеров
ldi temp, 0b01000001
out TIMSK,temp

ldi temp, timer2
out TCCR2, temp	
ldi temp, TIMER2_INTERVAL
out TCNT2, temp

ldi temp, timer0
out TCCR0, temp	 
ldi temp, TIMER1_INTERVAL
out TCNT0, temp

sei

LOOP:
rjmp LOOP

timer2_ovf:
cli
ldi ZH, HIGH(2*pong_str)
ldi ZL, LOW(2*pong_str)
rcall USART_PUT
ldi temp, TIMER2_INTERVAL
out TCNT2, temp
sei
reti 

timer0_ovf:
cli
ldi ZH, HIGH(2*ping_str)
ldi ZL, LOW(2*ping_str)
rcall USART_PUT
ldi temp, TIMER1_INTERVAL
out TCNT0, temp
sei
reti 

USART_PUT:
 lpm temp,Z+	
 cpi temp,end_character
 breq USART_PUT_END
  USART_PUT_WAIT:
   sbis UCSRA,UDRE
  rjmp USART_PUT_WAIT
  out UDR,temp
 rjmp USART_PUT
 USART_PUT_END:
ret
