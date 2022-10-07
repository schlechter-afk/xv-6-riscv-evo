
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	cc010113          	addi	sp,sp,-832 # 80008cc0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	b2e70713          	addi	a4,a4,-1234 # 80008b80 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	e2c78793          	addi	a5,a5,-468 # 80005e90 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc00f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3d8080e7          	jalr	984(ra) # 80002504 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	b3450513          	addi	a0,a0,-1228 # 80010cc0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	b2448493          	addi	s1,s1,-1244 # 80010cc0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	bb290913          	addi	s2,s2,-1102 # 80010d58 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	182080e7          	jalr	386(ra) # 8000234e <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	ecc080e7          	jalr	-308(ra) # 800020a6 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	298080e7          	jalr	664(ra) # 800024ae <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	a9650513          	addi	a0,a0,-1386 # 80010cc0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	a8050513          	addi	a0,a0,-1408 # 80010cc0 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	aef72023          	sw	a5,-1312(a4) # 80010d58 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	9ee50513          	addi	a0,a0,-1554 # 80010cc0 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	262080e7          	jalr	610(ra) # 8000255a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	9c050513          	addi	a0,a0,-1600 # 80010cc0 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	99c70713          	addi	a4,a4,-1636 # 80010cc0 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	97278793          	addi	a5,a5,-1678 # 80010cc0 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	9dc7a783          	lw	a5,-1572(a5) # 80010d58 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	93070713          	addi	a4,a4,-1744 # 80010cc0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	92048493          	addi	s1,s1,-1760 # 80010cc0 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	8e470713          	addi	a4,a4,-1820 # 80010cc0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	96f72723          	sw	a5,-1682(a4) # 80010d60 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	8a878793          	addi	a5,a5,-1880 # 80010cc0 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	92c7a023          	sw	a2,-1760(a5) # 80010d5c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	91450513          	addi	a0,a0,-1772 # 80010d58 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	cbe080e7          	jalr	-834(ra) # 8000210a <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00011517          	auipc	a0,0x11
    8000046a:	85a50513          	addi	a0,a0,-1958 # 80010cc0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	1da78793          	addi	a5,a5,474 # 80021658 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00011797          	auipc	a5,0x11
    80000554:	8207a823          	sw	zero,-2000(a5) # 80010d80 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	f8650513          	addi	a0,a0,-122 # 800084f8 <states.1728+0x230>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	5af72e23          	sw	a5,1468(a4) # 80008b40 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	7c0dad83          	lw	s11,1984(s11) # 80010d80 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	76a50513          	addi	a0,a0,1898 # 80010d68 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	60650513          	addi	a0,a0,1542 # 80010d68 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	5ea48493          	addi	s1,s1,1514 # 80010d68 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	5aa50513          	addi	a0,a0,1450 # 80010d88 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	3367a783          	lw	a5,822(a5) # 80008b40 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	30273703          	ld	a4,770(a4) # 80008b48 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	3027b783          	ld	a5,770(a5) # 80008b50 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	518a0a13          	addi	s4,s4,1304 # 80010d88 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	2d048493          	addi	s1,s1,720 # 80008b48 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	2d098993          	addi	s3,s3,720 # 80008b50 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	864080e7          	jalr	-1948(ra) # 8000210a <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	4a650513          	addi	a0,a0,1190 # 80010d88 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	24e7a783          	lw	a5,590(a5) # 80008b40 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2547b783          	ld	a5,596(a5) # 80008b50 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	24473703          	ld	a4,580(a4) # 80008b48 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	478a0a13          	addi	s4,s4,1144 # 80010d88 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	23048493          	addi	s1,s1,560 # 80008b48 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	23090913          	addi	s2,s2,560 # 80008b50 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	776080e7          	jalr	1910(ra) # 800020a6 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	44248493          	addi	s1,s1,1090 # 80010d88 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	1ef73b23          	sd	a5,502(a4) # 80008b50 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	3b848493          	addi	s1,s1,952 # 80010d88 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00022797          	auipc	a5,0x22
    80000a16:	dde78793          	addi	a5,a5,-546 # 800227f0 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	38e90913          	addi	s2,s2,910 # 80010dc0 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	2f250513          	addi	a0,a0,754 # 80010dc0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00022517          	auipc	a0,0x22
    80000ae6:	d0e50513          	addi	a0,a0,-754 # 800227f0 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	2bc48493          	addi	s1,s1,700 # 80010dc0 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	2a450513          	addi	a0,a0,676 # 80010dc0 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	27850513          	addi	a0,a0,632 # 80010dc0 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	cb470713          	addi	a4,a4,-844 # 80008b58 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	7c0080e7          	jalr	1984(ra) # 8000269a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	fee080e7          	jalr	-18(ra) # 80005ed0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	00a080e7          	jalr	10(ra) # 80001ef4 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	5f650513          	addi	a0,a0,1526 # 800084f8 <states.1728+0x230>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	5d650513          	addi	a0,a0,1494 # 800084f8 <states.1728+0x230>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	720080e7          	jalr	1824(ra) # 80002672 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	740080e7          	jalr	1856(ra) # 8000269a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f58080e7          	jalr	-168(ra) # 80005eba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	f66080e7          	jalr	-154(ra) # 80005ed0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	120080e7          	jalr	288(ra) # 80003092 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	7c4080e7          	jalr	1988(ra) # 8000373e <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	762080e7          	jalr	1890(ra) # 800046e4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	04e080e7          	jalr	78(ra) # 80005fd8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d48080e7          	jalr	-696(ra) # 80001cda <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	baf72c23          	sw	a5,-1096(a4) # 80008b58 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	bac7b783          	ld	a5,-1108(a5) # 80008b60 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00008797          	auipc	a5,0x8
    80001274:	8ea7b823          	sd	a0,-1808(a5) # 80008b60 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00010497          	auipc	s1,0x10
    8000186a:	9aa48493          	addi	s1,s1,-1622 # 80011210 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001880:	00016a17          	auipc	s4,0x16
    80001884:	b90a0a13          	addi	s4,s4,-1136 # 80017410 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018ba:	18848493          	addi	s1,s1,392
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	4de50513          	addi	a0,a0,1246 # 80010de0 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	4de50513          	addi	a0,a0,1246 # 80010df8 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	8e648493          	addi	s1,s1,-1818 # 80011210 <proc>
  {
    initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000194c:	00016997          	auipc	s3,0x16
    80001950:	ac498993          	addi	s3,s3,-1340 # 80017410 <tickslock>
    initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
    p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000197e:	18848493          	addi	s1,s1,392
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	45a50513          	addi	a0,a0,1114 # 80010e10 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	40270713          	addi	a4,a4,1026 # 80010de0 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first)
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	fca7a783          	lw	a5,-54(a5) # 800089e0 <first.1684>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	c92080e7          	jalr	-878(ra) # 800026b2 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	fa07a823          	sw	zero,-80(a5) # 800089e0 <first.1684>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	c84080e7          	jalr	-892(ra) # 800036be <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	39090913          	addi	s2,s2,912 # 80010de0 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	f8278793          	addi	a5,a5,-126 # 800089e4 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  if (p->cpy_trapframe)
    80001b90:	1804b503          	ld	a0,384(s1)
    80001b94:	c509                	beqz	a0,80001b9e <freeproc+0x26>
    kfree((void *)p->cpy_trapframe);
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	e68080e7          	jalr	-408(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b9e:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001ba2:	68a8                	ld	a0,80(s1)
    80001ba4:	c511                	beqz	a0,80001bb0 <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba6:	64ac                	ld	a1,72(s1)
    80001ba8:	00000097          	auipc	ra,0x0
    80001bac:	f7e080e7          	jalr	-130(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001bb0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bb4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bbc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bc0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bc4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bcc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bd0:	0004ac23          	sw	zero,24(s1)
}
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6105                	addi	sp,sp,32
    80001bdc:	8082                	ret

0000000080001bde <allocproc>:
{
    80001bde:	1101                	addi	sp,sp,-32
    80001be0:	ec06                	sd	ra,24(sp)
    80001be2:	e822                	sd	s0,16(sp)
    80001be4:	e426                	sd	s1,8(sp)
    80001be6:	e04a                	sd	s2,0(sp)
    80001be8:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	0000f497          	auipc	s1,0xf
    80001bee:	62648493          	addi	s1,s1,1574 # 80011210 <proc>
    80001bf2:	00016917          	auipc	s2,0x16
    80001bf6:	81e90913          	addi	s2,s2,-2018 # 80017410 <tickslock>
    acquire(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	fee080e7          	jalr	-18(ra) # 80000bea <acquire>
    if (p->state == UNUSED)
    80001c04:	4c9c                	lw	a5,24(s1)
    80001c06:	cf81                	beqz	a5,80001c1e <allocproc+0x40>
      release(&p->lock);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	094080e7          	jalr	148(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c12:	18848493          	addi	s1,s1,392
    80001c16:	ff2492e3          	bne	s1,s2,80001bfa <allocproc+0x1c>
  return 0;
    80001c1a:	4481                	li	s1,0
    80001c1c:	a88d                	j	80001c8e <allocproc+0xb0>
  p->pid = allocpid();
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	e26080e7          	jalr	-474(ra) # 80001a44 <allocpid>
    80001c26:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c28:	4785                	li	a5,1
    80001c2a:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	ece080e7          	jalr	-306(ra) # 80000afa <kalloc>
    80001c34:	892a                	mv	s2,a0
    80001c36:	eca8                	sd	a0,88(s1)
    80001c38:	c135                	beqz	a0,80001c9c <allocproc+0xbe>
  if ((p->cpy_trapframe = (struct trapframe *)kalloc()) == 0)
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	ec0080e7          	jalr	-320(ra) # 80000afa <kalloc>
    80001c42:	892a                	mv	s2,a0
    80001c44:	18a4b023          	sd	a0,384(s1)
    80001c48:	c535                	beqz	a0,80001cb4 <allocproc+0xd6>
  p->is_sigalarm = 0;
    80001c4a:	1604a623          	sw	zero,364(s1)
  p->clockval = 0;
    80001c4e:	1604a823          	sw	zero,368(s1)
  p->completed_clockval = 0;
    80001c52:	1604aa23          	sw	zero,372(s1)
  p->handler = 0;
    80001c56:	1604bc23          	sd	zero,376(s1)
  p->pagetable = proc_pagetable(p);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	e2e080e7          	jalr	-466(ra) # 80001a8a <proc_pagetable>
    80001c64:	892a                	mv	s2,a0
    80001c66:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c68:	cd29                	beqz	a0,80001cc2 <allocproc+0xe4>
  memset(&p->context, 0, sizeof(p->context));
    80001c6a:	07000613          	li	a2,112
    80001c6e:	4581                	li	a1,0
    80001c70:	06048513          	addi	a0,s1,96
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	072080e7          	jalr	114(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c7c:	00000797          	auipc	a5,0x0
    80001c80:	d8278793          	addi	a5,a5,-638 # 800019fe <forkret>
    80001c84:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c86:	60bc                	ld	a5,64(s1)
    80001c88:	6705                	lui	a4,0x1
    80001c8a:	97ba                	add	a5,a5,a4
    80001c8c:	f4bc                	sd	a5,104(s1)
}
    80001c8e:	8526                	mv	a0,s1
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6902                	ld	s2,0(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret
    freeproc(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	eda080e7          	jalr	-294(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	ff6080e7          	jalr	-10(ra) # 80000c9e <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	bff1                	j	80001c8e <allocproc+0xb0>
    release(&p->lock);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	fe8080e7          	jalr	-24(ra) # 80000c9e <release>
    return 0;
    80001cbe:	84ca                	mv	s1,s2
    80001cc0:	b7f9                	j	80001c8e <allocproc+0xb0>
    freeproc(p);
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	00000097          	auipc	ra,0x0
    80001cc8:	eb4080e7          	jalr	-332(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	fd0080e7          	jalr	-48(ra) # 80000c9e <release>
    return 0;
    80001cd6:	84ca                	mv	s1,s2
    80001cd8:	bf5d                	j	80001c8e <allocproc+0xb0>

0000000080001cda <userinit>:
{
    80001cda:	1101                	addi	sp,sp,-32
    80001cdc:	ec06                	sd	ra,24(sp)
    80001cde:	e822                	sd	s0,16(sp)
    80001ce0:	e426                	sd	s1,8(sp)
    80001ce2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce4:	00000097          	auipc	ra,0x0
    80001ce8:	efa080e7          	jalr	-262(ra) # 80001bde <allocproc>
    80001cec:	84aa                	mv	s1,a0
  initproc = p;
    80001cee:	00007797          	auipc	a5,0x7
    80001cf2:	e6a7bd23          	sd	a0,-390(a5) # 80008b68 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cf6:	03400613          	li	a2,52
    80001cfa:	00007597          	auipc	a1,0x7
    80001cfe:	cf658593          	addi	a1,a1,-778 # 800089f0 <initcode>
    80001d02:	6928                	ld	a0,80(a0)
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	66e080e7          	jalr	1646(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001d0c:	6785                	lui	a5,0x1
    80001d0e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d10:	6cb8                	ld	a4,88(s1)
    80001d12:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d16:	6cb8                	ld	a4,88(s1)
    80001d18:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d1a:	4641                	li	a2,16
    80001d1c:	00006597          	auipc	a1,0x6
    80001d20:	4e458593          	addi	a1,a1,1252 # 80008200 <digits+0x1c0>
    80001d24:	15848513          	addi	a0,s1,344
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	110080e7          	jalr	272(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d30:	00006517          	auipc	a0,0x6
    80001d34:	4e050513          	addi	a0,a0,1248 # 80008210 <digits+0x1d0>
    80001d38:	00002097          	auipc	ra,0x2
    80001d3c:	3a8080e7          	jalr	936(ra) # 800040e0 <namei>
    80001d40:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d44:	478d                	li	a5,3
    80001d46:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d48:	8526                	mv	a0,s1
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	f54080e7          	jalr	-172(ra) # 80000c9e <release>
}
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6105                	addi	sp,sp,32
    80001d5a:	8082                	ret

0000000080001d5c <growproc>:
{
    80001d5c:	1101                	addi	sp,sp,-32
    80001d5e:	ec06                	sd	ra,24(sp)
    80001d60:	e822                	sd	s0,16(sp)
    80001d62:	e426                	sd	s1,8(sp)
    80001d64:	e04a                	sd	s2,0(sp)
    80001d66:	1000                	addi	s0,sp,32
    80001d68:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d6a:	00000097          	auipc	ra,0x0
    80001d6e:	c5c080e7          	jalr	-932(ra) # 800019c6 <myproc>
    80001d72:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d74:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d76:	01204c63          	bgtz	s2,80001d8e <growproc+0x32>
  else if (n < 0)
    80001d7a:	02094663          	bltz	s2,80001da6 <growproc+0x4a>
  p->sz = sz;
    80001d7e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d80:	4501                	li	a0,0
}
    80001d82:	60e2                	ld	ra,24(sp)
    80001d84:	6442                	ld	s0,16(sp)
    80001d86:	64a2                	ld	s1,8(sp)
    80001d88:	6902                	ld	s2,0(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d8e:	4691                	li	a3,4
    80001d90:	00b90633          	add	a2,s2,a1
    80001d94:	6928                	ld	a0,80(a0)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	696080e7          	jalr	1686(ra) # 8000142c <uvmalloc>
    80001d9e:	85aa                	mv	a1,a0
    80001da0:	fd79                	bnez	a0,80001d7e <growproc+0x22>
      return -1;
    80001da2:	557d                	li	a0,-1
    80001da4:	bff9                	j	80001d82 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da6:	00b90633          	add	a2,s2,a1
    80001daa:	6928                	ld	a0,80(a0)
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	638080e7          	jalr	1592(ra) # 800013e4 <uvmdealloc>
    80001db4:	85aa                	mv	a1,a0
    80001db6:	b7e1                	j	80001d7e <growproc+0x22>

0000000080001db8 <fork>:
{
    80001db8:	7179                	addi	sp,sp,-48
    80001dba:	f406                	sd	ra,40(sp)
    80001dbc:	f022                	sd	s0,32(sp)
    80001dbe:	ec26                	sd	s1,24(sp)
    80001dc0:	e84a                	sd	s2,16(sp)
    80001dc2:	e44e                	sd	s3,8(sp)
    80001dc4:	e052                	sd	s4,0(sp)
    80001dc6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dc8:	00000097          	auipc	ra,0x0
    80001dcc:	bfe080e7          	jalr	-1026(ra) # 800019c6 <myproc>
    80001dd0:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001dd2:	00000097          	auipc	ra,0x0
    80001dd6:	e0c080e7          	jalr	-500(ra) # 80001bde <allocproc>
    80001dda:	10050b63          	beqz	a0,80001ef0 <fork+0x138>
    80001dde:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001de0:	04893603          	ld	a2,72(s2)
    80001de4:	692c                	ld	a1,80(a0)
    80001de6:	05093503          	ld	a0,80(s2)
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	796080e7          	jalr	1942(ra) # 80001580 <uvmcopy>
    80001df2:	04054663          	bltz	a0,80001e3e <fork+0x86>
  np->sz = p->sz;
    80001df6:	04893783          	ld	a5,72(s2)
    80001dfa:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dfe:	05893683          	ld	a3,88(s2)
    80001e02:	87b6                	mv	a5,a3
    80001e04:	0589b703          	ld	a4,88(s3)
    80001e08:	12068693          	addi	a3,a3,288
    80001e0c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e10:	6788                	ld	a0,8(a5)
    80001e12:	6b8c                	ld	a1,16(a5)
    80001e14:	6f90                	ld	a2,24(a5)
    80001e16:	01073023          	sd	a6,0(a4)
    80001e1a:	e708                	sd	a0,8(a4)
    80001e1c:	eb0c                	sd	a1,16(a4)
    80001e1e:	ef10                	sd	a2,24(a4)
    80001e20:	02078793          	addi	a5,a5,32
    80001e24:	02070713          	addi	a4,a4,32
    80001e28:	fed792e3          	bne	a5,a3,80001e0c <fork+0x54>
  np->trapframe->a0 = 0;
    80001e2c:	0589b783          	ld	a5,88(s3)
    80001e30:	0607b823          	sd	zero,112(a5)
    80001e34:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001e38:	15000a13          	li	s4,336
    80001e3c:	a03d                	j	80001e6a <fork+0xb2>
    freeproc(np);
    80001e3e:	854e                	mv	a0,s3
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	d38080e7          	jalr	-712(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e48:	854e                	mv	a0,s3
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e54080e7          	jalr	-428(ra) # 80000c9e <release>
    return -1;
    80001e52:	5a7d                	li	s4,-1
    80001e54:	a069                	j	80001ede <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e56:	00003097          	auipc	ra,0x3
    80001e5a:	920080e7          	jalr	-1760(ra) # 80004776 <filedup>
    80001e5e:	009987b3          	add	a5,s3,s1
    80001e62:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e64:	04a1                	addi	s1,s1,8
    80001e66:	01448763          	beq	s1,s4,80001e74 <fork+0xbc>
    if (p->ofile[i])
    80001e6a:	009907b3          	add	a5,s2,s1
    80001e6e:	6388                	ld	a0,0(a5)
    80001e70:	f17d                	bnez	a0,80001e56 <fork+0x9e>
    80001e72:	bfcd                	j	80001e64 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e74:	15093503          	ld	a0,336(s2)
    80001e78:	00002097          	auipc	ra,0x2
    80001e7c:	a84080e7          	jalr	-1404(ra) # 800038fc <idup>
    80001e80:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e84:	4641                	li	a2,16
    80001e86:	15890593          	addi	a1,s2,344
    80001e8a:	15898513          	addi	a0,s3,344
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	faa080e7          	jalr	-86(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e96:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	e02080e7          	jalr	-510(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001ea4:	0000f497          	auipc	s1,0xf
    80001ea8:	f5448493          	addi	s1,s1,-172 # 80010df8 <wait_lock>
    80001eac:	8526                	mv	a0,s1
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	d3c080e7          	jalr	-708(ra) # 80000bea <acquire>
  np->parent = p;
    80001eb6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	de2080e7          	jalr	-542(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001ec4:	854e                	mv	a0,s3
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	d24080e7          	jalr	-732(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001ece:	478d                	li	a5,3
    80001ed0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ed4:	854e                	mv	a0,s3
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	dc8080e7          	jalr	-568(ra) # 80000c9e <release>
}
    80001ede:	8552                	mv	a0,s4
    80001ee0:	70a2                	ld	ra,40(sp)
    80001ee2:	7402                	ld	s0,32(sp)
    80001ee4:	64e2                	ld	s1,24(sp)
    80001ee6:	6942                	ld	s2,16(sp)
    80001ee8:	69a2                	ld	s3,8(sp)
    80001eea:	6a02                	ld	s4,0(sp)
    80001eec:	6145                	addi	sp,sp,48
    80001eee:	8082                	ret
    return -1;
    80001ef0:	5a7d                	li	s4,-1
    80001ef2:	b7f5                	j	80001ede <fork+0x126>

0000000080001ef4 <scheduler>:
{
    80001ef4:	7139                	addi	sp,sp,-64
    80001ef6:	fc06                	sd	ra,56(sp)
    80001ef8:	f822                	sd	s0,48(sp)
    80001efa:	f426                	sd	s1,40(sp)
    80001efc:	f04a                	sd	s2,32(sp)
    80001efe:	ec4e                	sd	s3,24(sp)
    80001f00:	e852                	sd	s4,16(sp)
    80001f02:	e456                	sd	s5,8(sp)
    80001f04:	e05a                	sd	s6,0(sp)
    80001f06:	0080                	addi	s0,sp,64
    80001f08:	8792                	mv	a5,tp
  int id = r_tp();
    80001f0a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0c:	00779a93          	slli	s5,a5,0x7
    80001f10:	0000f717          	auipc	a4,0xf
    80001f14:	ed070713          	addi	a4,a4,-304 # 80010de0 <pid_lock>
    80001f18:	9756                	add	a4,a4,s5
    80001f1a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f1e:	0000f717          	auipc	a4,0xf
    80001f22:	efa70713          	addi	a4,a4,-262 # 80010e18 <cpus+0x8>
    80001f26:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f28:	498d                	li	s3,3
        p->state = RUNNING;
    80001f2a:	4b11                	li	s6,4
        c->proc = p;
    80001f2c:	079e                	slli	a5,a5,0x7
    80001f2e:	0000fa17          	auipc	s4,0xf
    80001f32:	eb2a0a13          	addi	s4,s4,-334 # 80010de0 <pid_lock>
    80001f36:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f38:	00015917          	auipc	s2,0x15
    80001f3c:	4d890913          	addi	s2,s2,1240 # 80017410 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f44:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f48:	10079073          	csrw	sstatus,a5
    80001f4c:	0000f497          	auipc	s1,0xf
    80001f50:	2c448493          	addi	s1,s1,708 # 80011210 <proc>
    80001f54:	a03d                	j	80001f82 <scheduler+0x8e>
        p->state = RUNNING;
    80001f56:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f5a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f5e:	06048593          	addi	a1,s1,96
    80001f62:	8556                	mv	a0,s5
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	6a4080e7          	jalr	1700(ra) # 80002608 <swtch>
        c->proc = 0;
    80001f6c:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	d2c080e7          	jalr	-724(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f7a:	18848493          	addi	s1,s1,392
    80001f7e:	fd2481e3          	beq	s1,s2,80001f40 <scheduler+0x4c>
      acquire(&p->lock);
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	c66080e7          	jalr	-922(ra) # 80000bea <acquire>
      if (p->state == RUNNABLE)
    80001f8c:	4c9c                	lw	a5,24(s1)
    80001f8e:	ff3791e3          	bne	a5,s3,80001f70 <scheduler+0x7c>
    80001f92:	b7d1                	j	80001f56 <scheduler+0x62>

0000000080001f94 <sched>:
{
    80001f94:	7179                	addi	sp,sp,-48
    80001f96:	f406                	sd	ra,40(sp)
    80001f98:	f022                	sd	s0,32(sp)
    80001f9a:	ec26                	sd	s1,24(sp)
    80001f9c:	e84a                	sd	s2,16(sp)
    80001f9e:	e44e                	sd	s3,8(sp)
    80001fa0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	a24080e7          	jalr	-1500(ra) # 800019c6 <myproc>
    80001faa:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	bc4080e7          	jalr	-1084(ra) # 80000b70 <holding>
    80001fb4:	c93d                	beqz	a0,8000202a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb6:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	slli	a5,a5,0x7
    80001fbc:	0000f717          	auipc	a4,0xf
    80001fc0:	e2470713          	addi	a4,a4,-476 # 80010de0 <pid_lock>
    80001fc4:	97ba                	add	a5,a5,a4
    80001fc6:	0a87a703          	lw	a4,168(a5)
    80001fca:	4785                	li	a5,1
    80001fcc:	06f71763          	bne	a4,a5,8000203a <sched+0xa6>
  if (p->state == RUNNING)
    80001fd0:	4c98                	lw	a4,24(s1)
    80001fd2:	4791                	li	a5,4
    80001fd4:	06f70b63          	beq	a4,a5,8000204a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fdc:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fde:	efb5                	bnez	a5,8000205a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fe2:	0000f917          	auipc	s2,0xf
    80001fe6:	dfe90913          	addi	s2,s2,-514 # 80010de0 <pid_lock>
    80001fea:	2781                	sext.w	a5,a5
    80001fec:	079e                	slli	a5,a5,0x7
    80001fee:	97ca                	add	a5,a5,s2
    80001ff0:	0ac7a983          	lw	s3,172(a5)
    80001ff4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff6:	2781                	sext.w	a5,a5
    80001ff8:	079e                	slli	a5,a5,0x7
    80001ffa:	0000f597          	auipc	a1,0xf
    80001ffe:	e1e58593          	addi	a1,a1,-482 # 80010e18 <cpus+0x8>
    80002002:	95be                	add	a1,a1,a5
    80002004:	06048513          	addi	a0,s1,96
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	600080e7          	jalr	1536(ra) # 80002608 <swtch>
    80002010:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002012:	2781                	sext.w	a5,a5
    80002014:	079e                	slli	a5,a5,0x7
    80002016:	97ca                	add	a5,a5,s2
    80002018:	0b37a623          	sw	s3,172(a5)
}
    8000201c:	70a2                	ld	ra,40(sp)
    8000201e:	7402                	ld	s0,32(sp)
    80002020:	64e2                	ld	s1,24(sp)
    80002022:	6942                	ld	s2,16(sp)
    80002024:	69a2                	ld	s3,8(sp)
    80002026:	6145                	addi	sp,sp,48
    80002028:	8082                	ret
    panic("sched p->lock");
    8000202a:	00006517          	auipc	a0,0x6
    8000202e:	1ee50513          	addi	a0,a0,494 # 80008218 <digits+0x1d8>
    80002032:	ffffe097          	auipc	ra,0xffffe
    80002036:	512080e7          	jalr	1298(ra) # 80000544 <panic>
    panic("sched locks");
    8000203a:	00006517          	auipc	a0,0x6
    8000203e:	1ee50513          	addi	a0,a0,494 # 80008228 <digits+0x1e8>
    80002042:	ffffe097          	auipc	ra,0xffffe
    80002046:	502080e7          	jalr	1282(ra) # 80000544 <panic>
    panic("sched running");
    8000204a:	00006517          	auipc	a0,0x6
    8000204e:	1ee50513          	addi	a0,a0,494 # 80008238 <digits+0x1f8>
    80002052:	ffffe097          	auipc	ra,0xffffe
    80002056:	4f2080e7          	jalr	1266(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	1ee50513          	addi	a0,a0,494 # 80008248 <digits+0x208>
    80002062:	ffffe097          	auipc	ra,0xffffe
    80002066:	4e2080e7          	jalr	1250(ra) # 80000544 <panic>

000000008000206a <yield>:
{
    8000206a:	1101                	addi	sp,sp,-32
    8000206c:	ec06                	sd	ra,24(sp)
    8000206e:	e822                	sd	s0,16(sp)
    80002070:	e426                	sd	s1,8(sp)
    80002072:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	952080e7          	jalr	-1710(ra) # 800019c6 <myproc>
    8000207c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	b6c080e7          	jalr	-1172(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002086:	478d                	li	a5,3
    80002088:	cc9c                	sw	a5,24(s1)
  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	f0a080e7          	jalr	-246(ra) # 80001f94 <sched>
  release(&p->lock);
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	c0a080e7          	jalr	-1014(ra) # 80000c9e <release>
}
    8000209c:	60e2                	ld	ra,24(sp)
    8000209e:	6442                	ld	s0,16(sp)
    800020a0:	64a2                	ld	s1,8(sp)
    800020a2:	6105                	addi	sp,sp,32
    800020a4:	8082                	ret

00000000800020a6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020a6:	7179                	addi	sp,sp,-48
    800020a8:	f406                	sd	ra,40(sp)
    800020aa:	f022                	sd	s0,32(sp)
    800020ac:	ec26                	sd	s1,24(sp)
    800020ae:	e84a                	sd	s2,16(sp)
    800020b0:	e44e                	sd	s3,8(sp)
    800020b2:	1800                	addi	s0,sp,48
    800020b4:	89aa                	mv	s3,a0
    800020b6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	90e080e7          	jalr	-1778(ra) # 800019c6 <myproc>
    800020c0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	b28080e7          	jalr	-1240(ra) # 80000bea <acquire>
  release(lk);
    800020ca:	854a                	mv	a0,s2
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	bd2080e7          	jalr	-1070(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800020d4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d8:	4789                	li	a5,2
    800020da:	cc9c                	sw	a5,24(s1)

  sched();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	eb8080e7          	jalr	-328(ra) # 80001f94 <sched>

  // Tidy up.
  p->chan = 0;
    800020e4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	bb4080e7          	jalr	-1100(ra) # 80000c9e <release>
  acquire(lk);
    800020f2:	854a                	mv	a0,s2
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	af6080e7          	jalr	-1290(ra) # 80000bea <acquire>
}
    800020fc:	70a2                	ld	ra,40(sp)
    800020fe:	7402                	ld	s0,32(sp)
    80002100:	64e2                	ld	s1,24(sp)
    80002102:	6942                	ld	s2,16(sp)
    80002104:	69a2                	ld	s3,8(sp)
    80002106:	6145                	addi	sp,sp,48
    80002108:	8082                	ret

000000008000210a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000210a:	7139                	addi	sp,sp,-64
    8000210c:	fc06                	sd	ra,56(sp)
    8000210e:	f822                	sd	s0,48(sp)
    80002110:	f426                	sd	s1,40(sp)
    80002112:	f04a                	sd	s2,32(sp)
    80002114:	ec4e                	sd	s3,24(sp)
    80002116:	e852                	sd	s4,16(sp)
    80002118:	e456                	sd	s5,8(sp)
    8000211a:	0080                	addi	s0,sp,64
    8000211c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000211e:	0000f497          	auipc	s1,0xf
    80002122:	0f248493          	addi	s1,s1,242 # 80011210 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002126:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002128:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000212a:	00015917          	auipc	s2,0x15
    8000212e:	2e690913          	addi	s2,s2,742 # 80017410 <tickslock>
    80002132:	a821                	j	8000214a <wakeup+0x40>
        p->state = RUNNABLE;
    80002134:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	b64080e7          	jalr	-1180(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002142:	18848493          	addi	s1,s1,392
    80002146:	03248463          	beq	s1,s2,8000216e <wakeup+0x64>
    if (p != myproc())
    8000214a:	00000097          	auipc	ra,0x0
    8000214e:	87c080e7          	jalr	-1924(ra) # 800019c6 <myproc>
    80002152:	fea488e3          	beq	s1,a0,80002142 <wakeup+0x38>
      acquire(&p->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	a92080e7          	jalr	-1390(ra) # 80000bea <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002160:	4c9c                	lw	a5,24(s1)
    80002162:	fd379be3          	bne	a5,s3,80002138 <wakeup+0x2e>
    80002166:	709c                	ld	a5,32(s1)
    80002168:	fd4798e3          	bne	a5,s4,80002138 <wakeup+0x2e>
    8000216c:	b7e1                	j	80002134 <wakeup+0x2a>
    }
  }
}
    8000216e:	70e2                	ld	ra,56(sp)
    80002170:	7442                	ld	s0,48(sp)
    80002172:	74a2                	ld	s1,40(sp)
    80002174:	7902                	ld	s2,32(sp)
    80002176:	69e2                	ld	s3,24(sp)
    80002178:	6a42                	ld	s4,16(sp)
    8000217a:	6aa2                	ld	s5,8(sp)
    8000217c:	6121                	addi	sp,sp,64
    8000217e:	8082                	ret

0000000080002180 <reparent>:
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	e052                	sd	s4,0(sp)
    8000218e:	1800                	addi	s0,sp,48
    80002190:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002192:	0000f497          	auipc	s1,0xf
    80002196:	07e48493          	addi	s1,s1,126 # 80011210 <proc>
      pp->parent = initproc;
    8000219a:	00007a17          	auipc	s4,0x7
    8000219e:	9cea0a13          	addi	s4,s4,-1586 # 80008b68 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021a2:	00015997          	auipc	s3,0x15
    800021a6:	26e98993          	addi	s3,s3,622 # 80017410 <tickslock>
    800021aa:	a029                	j	800021b4 <reparent+0x34>
    800021ac:	18848493          	addi	s1,s1,392
    800021b0:	01348d63          	beq	s1,s3,800021ca <reparent+0x4a>
    if (pp->parent == p)
    800021b4:	7c9c                	ld	a5,56(s1)
    800021b6:	ff279be3          	bne	a5,s2,800021ac <reparent+0x2c>
      pp->parent = initproc;
    800021ba:	000a3503          	ld	a0,0(s4)
    800021be:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	f4a080e7          	jalr	-182(ra) # 8000210a <wakeup>
    800021c8:	b7d5                	j	800021ac <reparent+0x2c>
}
    800021ca:	70a2                	ld	ra,40(sp)
    800021cc:	7402                	ld	s0,32(sp)
    800021ce:	64e2                	ld	s1,24(sp)
    800021d0:	6942                	ld	s2,16(sp)
    800021d2:	69a2                	ld	s3,8(sp)
    800021d4:	6a02                	ld	s4,0(sp)
    800021d6:	6145                	addi	sp,sp,48
    800021d8:	8082                	ret

00000000800021da <exit>:
{
    800021da:	7179                	addi	sp,sp,-48
    800021dc:	f406                	sd	ra,40(sp)
    800021de:	f022                	sd	s0,32(sp)
    800021e0:	ec26                	sd	s1,24(sp)
    800021e2:	e84a                	sd	s2,16(sp)
    800021e4:	e44e                	sd	s3,8(sp)
    800021e6:	e052                	sd	s4,0(sp)
    800021e8:	1800                	addi	s0,sp,48
    800021ea:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	7da080e7          	jalr	2010(ra) # 800019c6 <myproc>
    800021f4:	89aa                	mv	s3,a0
  if (p == initproc)
    800021f6:	00007797          	auipc	a5,0x7
    800021fa:	9727b783          	ld	a5,-1678(a5) # 80008b68 <initproc>
    800021fe:	0d050493          	addi	s1,a0,208
    80002202:	15050913          	addi	s2,a0,336
    80002206:	02a79363          	bne	a5,a0,8000222c <exit+0x52>
    panic("init exiting");
    8000220a:	00006517          	auipc	a0,0x6
    8000220e:	05650513          	addi	a0,a0,86 # 80008260 <digits+0x220>
    80002212:	ffffe097          	auipc	ra,0xffffe
    80002216:	332080e7          	jalr	818(ra) # 80000544 <panic>
      fileclose(f);
    8000221a:	00002097          	auipc	ra,0x2
    8000221e:	5ae080e7          	jalr	1454(ra) # 800047c8 <fileclose>
      p->ofile[fd] = 0;
    80002222:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002226:	04a1                	addi	s1,s1,8
    80002228:	01248563          	beq	s1,s2,80002232 <exit+0x58>
    if (p->ofile[fd])
    8000222c:	6088                	ld	a0,0(s1)
    8000222e:	f575                	bnez	a0,8000221a <exit+0x40>
    80002230:	bfdd                	j	80002226 <exit+0x4c>
  begin_op();
    80002232:	00002097          	auipc	ra,0x2
    80002236:	0ca080e7          	jalr	202(ra) # 800042fc <begin_op>
  iput(p->cwd);
    8000223a:	1509b503          	ld	a0,336(s3)
    8000223e:	00002097          	auipc	ra,0x2
    80002242:	8b6080e7          	jalr	-1866(ra) # 80003af4 <iput>
  end_op();
    80002246:	00002097          	auipc	ra,0x2
    8000224a:	136080e7          	jalr	310(ra) # 8000437c <end_op>
  p->cwd = 0;
    8000224e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002252:	0000f497          	auipc	s1,0xf
    80002256:	ba648493          	addi	s1,s1,-1114 # 80010df8 <wait_lock>
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	98e080e7          	jalr	-1650(ra) # 80000bea <acquire>
  reparent(p);
    80002264:	854e                	mv	a0,s3
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	f1a080e7          	jalr	-230(ra) # 80002180 <reparent>
  wakeup(p->parent);
    8000226e:	0389b503          	ld	a0,56(s3)
    80002272:	00000097          	auipc	ra,0x0
    80002276:	e98080e7          	jalr	-360(ra) # 8000210a <wakeup>
  acquire(&p->lock);
    8000227a:	854e                	mv	a0,s3
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	96e080e7          	jalr	-1682(ra) # 80000bea <acquire>
  p->xstate = status;
    80002284:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002288:	4795                	li	a5,5
    8000228a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	a0e080e7          	jalr	-1522(ra) # 80000c9e <release>
  sched();
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	cfc080e7          	jalr	-772(ra) # 80001f94 <sched>
  panic("zombie exit");
    800022a0:	00006517          	auipc	a0,0x6
    800022a4:	fd050513          	addi	a0,a0,-48 # 80008270 <digits+0x230>
    800022a8:	ffffe097          	auipc	ra,0xffffe
    800022ac:	29c080e7          	jalr	668(ra) # 80000544 <panic>

00000000800022b0 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800022b0:	7179                	addi	sp,sp,-48
    800022b2:	f406                	sd	ra,40(sp)
    800022b4:	f022                	sd	s0,32(sp)
    800022b6:	ec26                	sd	s1,24(sp)
    800022b8:	e84a                	sd	s2,16(sp)
    800022ba:	e44e                	sd	s3,8(sp)
    800022bc:	1800                	addi	s0,sp,48
    800022be:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022c0:	0000f497          	auipc	s1,0xf
    800022c4:	f5048493          	addi	s1,s1,-176 # 80011210 <proc>
    800022c8:	00015997          	auipc	s3,0x15
    800022cc:	14898993          	addi	s3,s3,328 # 80017410 <tickslock>
  {
    acquire(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	918080e7          	jalr	-1768(ra) # 80000bea <acquire>
    if (p->pid == pid)
    800022da:	589c                	lw	a5,48(s1)
    800022dc:	01278d63          	beq	a5,s2,800022f6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9bc080e7          	jalr	-1604(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022ea:	18848493          	addi	s1,s1,392
    800022ee:	ff3491e3          	bne	s1,s3,800022d0 <kill+0x20>
  }
  return -1;
    800022f2:	557d                	li	a0,-1
    800022f4:	a829                	j	8000230e <kill+0x5e>
      p->killed = 1;
    800022f6:	4785                	li	a5,1
    800022f8:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022fa:	4c98                	lw	a4,24(s1)
    800022fc:	4789                	li	a5,2
    800022fe:	00f70f63          	beq	a4,a5,8000231c <kill+0x6c>
      release(&p->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	99a080e7          	jalr	-1638(ra) # 80000c9e <release>
      return 0;
    8000230c:	4501                	li	a0,0
}
    8000230e:	70a2                	ld	ra,40(sp)
    80002310:	7402                	ld	s0,32(sp)
    80002312:	64e2                	ld	s1,24(sp)
    80002314:	6942                	ld	s2,16(sp)
    80002316:	69a2                	ld	s3,8(sp)
    80002318:	6145                	addi	sp,sp,48
    8000231a:	8082                	ret
        p->state = RUNNABLE;
    8000231c:	478d                	li	a5,3
    8000231e:	cc9c                	sw	a5,24(s1)
    80002320:	b7cd                	j	80002302 <kill+0x52>

0000000080002322 <setkilled>:

void setkilled(struct proc *p)
{
    80002322:	1101                	addi	sp,sp,-32
    80002324:	ec06                	sd	ra,24(sp)
    80002326:	e822                	sd	s0,16(sp)
    80002328:	e426                	sd	s1,8(sp)
    8000232a:	1000                	addi	s0,sp,32
    8000232c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8bc080e7          	jalr	-1860(ra) # 80000bea <acquire>
  p->killed = 1;
    80002336:	4785                	li	a5,1
    80002338:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	962080e7          	jalr	-1694(ra) # 80000c9e <release>
}
    80002344:	60e2                	ld	ra,24(sp)
    80002346:	6442                	ld	s0,16(sp)
    80002348:	64a2                	ld	s1,8(sp)
    8000234a:	6105                	addi	sp,sp,32
    8000234c:	8082                	ret

000000008000234e <killed>:

int killed(struct proc *p)
{
    8000234e:	1101                	addi	sp,sp,-32
    80002350:	ec06                	sd	ra,24(sp)
    80002352:	e822                	sd	s0,16(sp)
    80002354:	e426                	sd	s1,8(sp)
    80002356:	e04a                	sd	s2,0(sp)
    80002358:	1000                	addi	s0,sp,32
    8000235a:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	88e080e7          	jalr	-1906(ra) # 80000bea <acquire>
  k = p->killed;
    80002364:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	934080e7          	jalr	-1740(ra) # 80000c9e <release>
  return k;
}
    80002372:	854a                	mv	a0,s2
    80002374:	60e2                	ld	ra,24(sp)
    80002376:	6442                	ld	s0,16(sp)
    80002378:	64a2                	ld	s1,8(sp)
    8000237a:	6902                	ld	s2,0(sp)
    8000237c:	6105                	addi	sp,sp,32
    8000237e:	8082                	ret

0000000080002380 <wait>:
{
    80002380:	715d                	addi	sp,sp,-80
    80002382:	e486                	sd	ra,72(sp)
    80002384:	e0a2                	sd	s0,64(sp)
    80002386:	fc26                	sd	s1,56(sp)
    80002388:	f84a                	sd	s2,48(sp)
    8000238a:	f44e                	sd	s3,40(sp)
    8000238c:	f052                	sd	s4,32(sp)
    8000238e:	ec56                	sd	s5,24(sp)
    80002390:	e85a                	sd	s6,16(sp)
    80002392:	e45e                	sd	s7,8(sp)
    80002394:	e062                	sd	s8,0(sp)
    80002396:	0880                	addi	s0,sp,80
    80002398:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	62c080e7          	jalr	1580(ra) # 800019c6 <myproc>
    800023a2:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023a4:	0000f517          	auipc	a0,0xf
    800023a8:	a5450513          	addi	a0,a0,-1452 # 80010df8 <wait_lock>
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	83e080e7          	jalr	-1986(ra) # 80000bea <acquire>
    havekids = 0;
    800023b4:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800023b6:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023b8:	00015997          	auipc	s3,0x15
    800023bc:	05898993          	addi	s3,s3,88 # 80017410 <tickslock>
        havekids = 1;
    800023c0:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023c2:	0000fc17          	auipc	s8,0xf
    800023c6:	a36c0c13          	addi	s8,s8,-1482 # 80010df8 <wait_lock>
    havekids = 0;
    800023ca:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023cc:	0000f497          	auipc	s1,0xf
    800023d0:	e4448493          	addi	s1,s1,-444 # 80011210 <proc>
    800023d4:	a0bd                	j	80002442 <wait+0xc2>
          pid = pp->pid;
    800023d6:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023da:	000b0e63          	beqz	s6,800023f6 <wait+0x76>
    800023de:	4691                	li	a3,4
    800023e0:	02c48613          	addi	a2,s1,44
    800023e4:	85da                	mv	a1,s6
    800023e6:	05093503          	ld	a0,80(s2)
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	29a080e7          	jalr	666(ra) # 80001684 <copyout>
    800023f2:	02054563          	bltz	a0,8000241c <wait+0x9c>
          freeproc(pp);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	780080e7          	jalr	1920(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	89c080e7          	jalr	-1892(ra) # 80000c9e <release>
          release(&wait_lock);
    8000240a:	0000f517          	auipc	a0,0xf
    8000240e:	9ee50513          	addi	a0,a0,-1554 # 80010df8 <wait_lock>
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	88c080e7          	jalr	-1908(ra) # 80000c9e <release>
          return pid;
    8000241a:	a0b5                	j	80002486 <wait+0x106>
            release(&pp->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	880080e7          	jalr	-1920(ra) # 80000c9e <release>
            release(&wait_lock);
    80002426:	0000f517          	auipc	a0,0xf
    8000242a:	9d250513          	addi	a0,a0,-1582 # 80010df8 <wait_lock>
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	870080e7          	jalr	-1936(ra) # 80000c9e <release>
            return -1;
    80002436:	59fd                	li	s3,-1
    80002438:	a0b9                	j	80002486 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000243a:	18848493          	addi	s1,s1,392
    8000243e:	03348463          	beq	s1,s3,80002466 <wait+0xe6>
      if (pp->parent == p)
    80002442:	7c9c                	ld	a5,56(s1)
    80002444:	ff279be3          	bne	a5,s2,8000243a <wait+0xba>
        acquire(&pp->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	7a0080e7          	jalr	1952(ra) # 80000bea <acquire>
        if (pp->state == ZOMBIE)
    80002452:	4c9c                	lw	a5,24(s1)
    80002454:	f94781e3          	beq	a5,s4,800023d6 <wait+0x56>
        release(&pp->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	844080e7          	jalr	-1980(ra) # 80000c9e <release>
        havekids = 1;
    80002462:	8756                	mv	a4,s5
    80002464:	bfd9                	j	8000243a <wait+0xba>
    if (!havekids || killed(p))
    80002466:	c719                	beqz	a4,80002474 <wait+0xf4>
    80002468:	854a                	mv	a0,s2
    8000246a:	00000097          	auipc	ra,0x0
    8000246e:	ee4080e7          	jalr	-284(ra) # 8000234e <killed>
    80002472:	c51d                	beqz	a0,800024a0 <wait+0x120>
      release(&wait_lock);
    80002474:	0000f517          	auipc	a0,0xf
    80002478:	98450513          	addi	a0,a0,-1660 # 80010df8 <wait_lock>
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	822080e7          	jalr	-2014(ra) # 80000c9e <release>
      return -1;
    80002484:	59fd                	li	s3,-1
}
    80002486:	854e                	mv	a0,s3
    80002488:	60a6                	ld	ra,72(sp)
    8000248a:	6406                	ld	s0,64(sp)
    8000248c:	74e2                	ld	s1,56(sp)
    8000248e:	7942                	ld	s2,48(sp)
    80002490:	79a2                	ld	s3,40(sp)
    80002492:	7a02                	ld	s4,32(sp)
    80002494:	6ae2                	ld	s5,24(sp)
    80002496:	6b42                	ld	s6,16(sp)
    80002498:	6ba2                	ld	s7,8(sp)
    8000249a:	6c02                	ld	s8,0(sp)
    8000249c:	6161                	addi	sp,sp,80
    8000249e:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024a0:	85e2                	mv	a1,s8
    800024a2:	854a                	mv	a0,s2
    800024a4:	00000097          	auipc	ra,0x0
    800024a8:	c02080e7          	jalr	-1022(ra) # 800020a6 <sleep>
    havekids = 0;
    800024ac:	bf39                	j	800023ca <wait+0x4a>

00000000800024ae <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	e052                	sd	s4,0(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	84aa                	mv	s1,a0
    800024c0:	892e                	mv	s2,a1
    800024c2:	89b2                	mv	s3,a2
    800024c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	500080e7          	jalr	1280(ra) # 800019c6 <myproc>
  if (user_dst)
    800024ce:	c08d                	beqz	s1,800024f0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024d0:	86d2                	mv	a3,s4
    800024d2:	864e                	mv	a2,s3
    800024d4:	85ca                	mv	a1,s2
    800024d6:	6928                	ld	a0,80(a0)
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	1ac080e7          	jalr	428(ra) # 80001684 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024e0:	70a2                	ld	ra,40(sp)
    800024e2:	7402                	ld	s0,32(sp)
    800024e4:	64e2                	ld	s1,24(sp)
    800024e6:	6942                	ld	s2,16(sp)
    800024e8:	69a2                	ld	s3,8(sp)
    800024ea:	6a02                	ld	s4,0(sp)
    800024ec:	6145                	addi	sp,sp,48
    800024ee:	8082                	ret
    memmove((char *)dst, src, len);
    800024f0:	000a061b          	sext.w	a2,s4
    800024f4:	85ce                	mv	a1,s3
    800024f6:	854a                	mv	a0,s2
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	84e080e7          	jalr	-1970(ra) # 80000d46 <memmove>
    return 0;
    80002500:	8526                	mv	a0,s1
    80002502:	bff9                	j	800024e0 <either_copyout+0x32>

0000000080002504 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002504:	7179                	addi	sp,sp,-48
    80002506:	f406                	sd	ra,40(sp)
    80002508:	f022                	sd	s0,32(sp)
    8000250a:	ec26                	sd	s1,24(sp)
    8000250c:	e84a                	sd	s2,16(sp)
    8000250e:	e44e                	sd	s3,8(sp)
    80002510:	e052                	sd	s4,0(sp)
    80002512:	1800                	addi	s0,sp,48
    80002514:	892a                	mv	s2,a0
    80002516:	84ae                	mv	s1,a1
    80002518:	89b2                	mv	s3,a2
    8000251a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	4aa080e7          	jalr	1194(ra) # 800019c6 <myproc>
  if (user_src)
    80002524:	c08d                	beqz	s1,80002546 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002526:	86d2                	mv	a3,s4
    80002528:	864e                	mv	a2,s3
    8000252a:	85ca                	mv	a1,s2
    8000252c:	6928                	ld	a0,80(a0)
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	1e2080e7          	jalr	482(ra) # 80001710 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002536:	70a2                	ld	ra,40(sp)
    80002538:	7402                	ld	s0,32(sp)
    8000253a:	64e2                	ld	s1,24(sp)
    8000253c:	6942                	ld	s2,16(sp)
    8000253e:	69a2                	ld	s3,8(sp)
    80002540:	6a02                	ld	s4,0(sp)
    80002542:	6145                	addi	sp,sp,48
    80002544:	8082                	ret
    memmove(dst, (char *)src, len);
    80002546:	000a061b          	sext.w	a2,s4
    8000254a:	85ce                	mv	a1,s3
    8000254c:	854a                	mv	a0,s2
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	7f8080e7          	jalr	2040(ra) # 80000d46 <memmove>
    return 0;
    80002556:	8526                	mv	a0,s1
    80002558:	bff9                	j	80002536 <either_copyin+0x32>

000000008000255a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000255a:	715d                	addi	sp,sp,-80
    8000255c:	e486                	sd	ra,72(sp)
    8000255e:	e0a2                	sd	s0,64(sp)
    80002560:	fc26                	sd	s1,56(sp)
    80002562:	f84a                	sd	s2,48(sp)
    80002564:	f44e                	sd	s3,40(sp)
    80002566:	f052                	sd	s4,32(sp)
    80002568:	ec56                	sd	s5,24(sp)
    8000256a:	e85a                	sd	s6,16(sp)
    8000256c:	e45e                	sd	s7,8(sp)
    8000256e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002570:	00006517          	auipc	a0,0x6
    80002574:	f8850513          	addi	a0,a0,-120 # 800084f8 <states.1728+0x230>
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	016080e7          	jalr	22(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002580:	0000f497          	auipc	s1,0xf
    80002584:	de848493          	addi	s1,s1,-536 # 80011368 <proc+0x158>
    80002588:	00015917          	auipc	s2,0x15
    8000258c:	fe090913          	addi	s2,s2,-32 # 80017568 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002590:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002592:	00006997          	auipc	s3,0x6
    80002596:	cee98993          	addi	s3,s3,-786 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000259a:	00006a97          	auipc	s5,0x6
    8000259e:	ceea8a93          	addi	s5,s5,-786 # 80008288 <digits+0x248>
    printf("\n");
    800025a2:	00006a17          	auipc	s4,0x6
    800025a6:	f56a0a13          	addi	s4,s4,-170 # 800084f8 <states.1728+0x230>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025aa:	00006b97          	auipc	s7,0x6
    800025ae:	d1eb8b93          	addi	s7,s7,-738 # 800082c8 <states.1728>
    800025b2:	a00d                	j	800025d4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b4:	ed86a583          	lw	a1,-296(a3)
    800025b8:	8556                	mv	a0,s5
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	fd4080e7          	jalr	-44(ra) # 8000058e <printf>
    printf("\n");
    800025c2:	8552                	mv	a0,s4
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	fca080e7          	jalr	-54(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025cc:	18848493          	addi	s1,s1,392
    800025d0:	03248163          	beq	s1,s2,800025f2 <procdump+0x98>
    if (p->state == UNUSED)
    800025d4:	86a6                	mv	a3,s1
    800025d6:	ec04a783          	lw	a5,-320(s1)
    800025da:	dbed                	beqz	a5,800025cc <procdump+0x72>
      state = "???";
    800025dc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025de:	fcfb6be3          	bltu	s6,a5,800025b4 <procdump+0x5a>
    800025e2:	1782                	slli	a5,a5,0x20
    800025e4:	9381                	srli	a5,a5,0x20
    800025e6:	078e                	slli	a5,a5,0x3
    800025e8:	97de                	add	a5,a5,s7
    800025ea:	6390                	ld	a2,0(a5)
    800025ec:	f661                	bnez	a2,800025b4 <procdump+0x5a>
      state = "???";
    800025ee:	864e                	mv	a2,s3
    800025f0:	b7d1                	j	800025b4 <procdump+0x5a>
  }
}
    800025f2:	60a6                	ld	ra,72(sp)
    800025f4:	6406                	ld	s0,64(sp)
    800025f6:	74e2                	ld	s1,56(sp)
    800025f8:	7942                	ld	s2,48(sp)
    800025fa:	79a2                	ld	s3,40(sp)
    800025fc:	7a02                	ld	s4,32(sp)
    800025fe:	6ae2                	ld	s5,24(sp)
    80002600:	6b42                	ld	s6,16(sp)
    80002602:	6ba2                	ld	s7,8(sp)
    80002604:	6161                	addi	sp,sp,80
    80002606:	8082                	ret

0000000080002608 <swtch>:
    80002608:	00153023          	sd	ra,0(a0)
    8000260c:	00253423          	sd	sp,8(a0)
    80002610:	e900                	sd	s0,16(a0)
    80002612:	ed04                	sd	s1,24(a0)
    80002614:	03253023          	sd	s2,32(a0)
    80002618:	03353423          	sd	s3,40(a0)
    8000261c:	03453823          	sd	s4,48(a0)
    80002620:	03553c23          	sd	s5,56(a0)
    80002624:	05653023          	sd	s6,64(a0)
    80002628:	05753423          	sd	s7,72(a0)
    8000262c:	05853823          	sd	s8,80(a0)
    80002630:	05953c23          	sd	s9,88(a0)
    80002634:	07a53023          	sd	s10,96(a0)
    80002638:	07b53423          	sd	s11,104(a0)
    8000263c:	0005b083          	ld	ra,0(a1)
    80002640:	0085b103          	ld	sp,8(a1)
    80002644:	6980                	ld	s0,16(a1)
    80002646:	6d84                	ld	s1,24(a1)
    80002648:	0205b903          	ld	s2,32(a1)
    8000264c:	0285b983          	ld	s3,40(a1)
    80002650:	0305ba03          	ld	s4,48(a1)
    80002654:	0385ba83          	ld	s5,56(a1)
    80002658:	0405bb03          	ld	s6,64(a1)
    8000265c:	0485bb83          	ld	s7,72(a1)
    80002660:	0505bc03          	ld	s8,80(a1)
    80002664:	0585bc83          	ld	s9,88(a1)
    80002668:	0605bd03          	ld	s10,96(a1)
    8000266c:	0685bd83          	ld	s11,104(a1)
    80002670:	8082                	ret

0000000080002672 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002672:	1141                	addi	sp,sp,-16
    80002674:	e406                	sd	ra,8(sp)
    80002676:	e022                	sd	s0,0(sp)
    80002678:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000267a:	00006597          	auipc	a1,0x6
    8000267e:	c7e58593          	addi	a1,a1,-898 # 800082f8 <states.1728+0x30>
    80002682:	00015517          	auipc	a0,0x15
    80002686:	d8e50513          	addi	a0,a0,-626 # 80017410 <tickslock>
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	4d0080e7          	jalr	1232(ra) # 80000b5a <initlock>
}
    80002692:	60a2                	ld	ra,8(sp)
    80002694:	6402                	ld	s0,0(sp)
    80002696:	0141                	addi	sp,sp,16
    80002698:	8082                	ret

000000008000269a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000269a:	1141                	addi	sp,sp,-16
    8000269c:	e422                	sd	s0,8(sp)
    8000269e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a0:	00003797          	auipc	a5,0x3
    800026a4:	76078793          	addi	a5,a5,1888 # 80005e00 <kernelvec>
    800026a8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ac:	6422                	ld	s0,8(sp)
    800026ae:	0141                	addi	sp,sp,16
    800026b0:	8082                	ret

00000000800026b2 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800026b2:	1141                	addi	sp,sp,-16
    800026b4:	e406                	sd	ra,8(sp)
    800026b6:	e022                	sd	s0,0(sp)
    800026b8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	30c080e7          	jalr	780(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026cc:	00005617          	auipc	a2,0x5
    800026d0:	93460613          	addi	a2,a2,-1740 # 80007000 <_trampoline>
    800026d4:	00005697          	auipc	a3,0x5
    800026d8:	92c68693          	addi	a3,a3,-1748 # 80007000 <_trampoline>
    800026dc:	8e91                	sub	a3,a3,a2
    800026de:	040007b7          	lui	a5,0x4000
    800026e2:	17fd                	addi	a5,a5,-1
    800026e4:	07b2                	slli	a5,a5,0xc
    800026e6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ec:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ee:	180026f3          	csrr	a3,satp
    800026f2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026f4:	6d38                	ld	a4,88(a0)
    800026f6:	6134                	ld	a3,64(a0)
    800026f8:	6585                	lui	a1,0x1
    800026fa:	96ae                	add	a3,a3,a1
    800026fc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026fe:	6d38                	ld	a4,88(a0)
    80002700:	00000697          	auipc	a3,0x0
    80002704:	13068693          	addi	a3,a3,304 # 80002830 <usertrap>
    80002708:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    8000270a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000270c:	8692                	mv	a3,tp
    8000270e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002710:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002714:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002718:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002720:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002722:	6f18                	ld	a4,24(a4)
    80002724:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002728:	6928                	ld	a0,80(a0)
    8000272a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000272c:	00005717          	auipc	a4,0x5
    80002730:	97070713          	addi	a4,a4,-1680 # 8000709c <userret>
    80002734:	8f11                	sub	a4,a4,a2
    80002736:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002738:	577d                	li	a4,-1
    8000273a:	177e                	slli	a4,a4,0x3f
    8000273c:	8d59                	or	a0,a0,a4
    8000273e:	9782                	jalr	a5
}
    80002740:	60a2                	ld	ra,8(sp)
    80002742:	6402                	ld	s0,0(sp)
    80002744:	0141                	addi	sp,sp,16
    80002746:	8082                	ret

0000000080002748 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002748:	1101                	addi	sp,sp,-32
    8000274a:	ec06                	sd	ra,24(sp)
    8000274c:	e822                	sd	s0,16(sp)
    8000274e:	e426                	sd	s1,8(sp)
    80002750:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002752:	00015497          	auipc	s1,0x15
    80002756:	cbe48493          	addi	s1,s1,-834 # 80017410 <tickslock>
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	48e080e7          	jalr	1166(ra) # 80000bea <acquire>
  ticks++;
    80002764:	00006517          	auipc	a0,0x6
    80002768:	40c50513          	addi	a0,a0,1036 # 80008b70 <ticks>
    8000276c:	411c                	lw	a5,0(a0)
    8000276e:	2785                	addiw	a5,a5,1
    80002770:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002772:	00000097          	auipc	ra,0x0
    80002776:	998080e7          	jalr	-1640(ra) # 8000210a <wakeup>
  release(&tickslock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	522080e7          	jalr	1314(ra) # 80000c9e <release>
}
    80002784:	60e2                	ld	ra,24(sp)
    80002786:	6442                	ld	s0,16(sp)
    80002788:	64a2                	ld	s1,8(sp)
    8000278a:	6105                	addi	sp,sp,32
    8000278c:	8082                	ret

000000008000278e <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    8000278e:	1101                	addi	sp,sp,-32
    80002790:	ec06                	sd	ra,24(sp)
    80002792:	e822                	sd	s0,16(sp)
    80002794:	e426                	sd	s1,8(sp)
    80002796:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002798:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    8000279c:	00074d63          	bltz	a4,800027b6 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    800027a0:	57fd                	li	a5,-1
    800027a2:	17fe                	slli	a5,a5,0x3f
    800027a4:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    800027a6:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    800027a8:	06f70363          	beq	a4,a5,8000280e <devintr+0x80>
  }
}
    800027ac:	60e2                	ld	ra,24(sp)
    800027ae:	6442                	ld	s0,16(sp)
    800027b0:	64a2                	ld	s1,8(sp)
    800027b2:	6105                	addi	sp,sp,32
    800027b4:	8082                	ret
      (scause & 0xff) == 9)
    800027b6:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    800027ba:	46a5                	li	a3,9
    800027bc:	fed792e3          	bne	a5,a3,800027a0 <devintr+0x12>
    int irq = plic_claim();
    800027c0:	00003097          	auipc	ra,0x3
    800027c4:	748080e7          	jalr	1864(ra) # 80005f08 <plic_claim>
    800027c8:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    800027ca:	47a9                	li	a5,10
    800027cc:	02f50763          	beq	a0,a5,800027fa <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    800027d0:	4785                	li	a5,1
    800027d2:	02f50963          	beq	a0,a5,80002804 <devintr+0x76>
    return 1;
    800027d6:	4505                	li	a0,1
    else if (irq)
    800027d8:	d8f1                	beqz	s1,800027ac <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027da:	85a6                	mv	a1,s1
    800027dc:	00006517          	auipc	a0,0x6
    800027e0:	b2450513          	addi	a0,a0,-1244 # 80008300 <states.1728+0x38>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	daa080e7          	jalr	-598(ra) # 8000058e <printf>
      plic_complete(irq);
    800027ec:	8526                	mv	a0,s1
    800027ee:	00003097          	auipc	ra,0x3
    800027f2:	73e080e7          	jalr	1854(ra) # 80005f2c <plic_complete>
    return 1;
    800027f6:	4505                	li	a0,1
    800027f8:	bf55                	j	800027ac <devintr+0x1e>
      uartintr();
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	1b4080e7          	jalr	436(ra) # 800009ae <uartintr>
    80002802:	b7ed                	j	800027ec <devintr+0x5e>
      virtio_disk_intr();
    80002804:	00004097          	auipc	ra,0x4
    80002808:	c52080e7          	jalr	-942(ra) # 80006456 <virtio_disk_intr>
    8000280c:	b7c5                	j	800027ec <devintr+0x5e>
    if (cpuid() == 0)
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	18c080e7          	jalr	396(ra) # 8000199a <cpuid>
    80002816:	c901                	beqz	a0,80002826 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002818:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000281c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000281e:	14479073          	csrw	sip,a5
    return 2;
    80002822:	4509                	li	a0,2
    80002824:	b761                	j	800027ac <devintr+0x1e>
      clockintr();
    80002826:	00000097          	auipc	ra,0x0
    8000282a:	f22080e7          	jalr	-222(ra) # 80002748 <clockintr>
    8000282e:	b7ed                	j	80002818 <devintr+0x8a>

0000000080002830 <usertrap>:
{
    80002830:	1101                	addi	sp,sp,-32
    80002832:	ec06                	sd	ra,24(sp)
    80002834:	e822                	sd	s0,16(sp)
    80002836:	e426                	sd	s1,8(sp)
    80002838:	e04a                	sd	s2,0(sp)
    8000283a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283c:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002840:	1007f793          	andi	a5,a5,256
    80002844:	e3b1                	bnez	a5,80002888 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002846:	00003797          	auipc	a5,0x3
    8000284a:	5ba78793          	addi	a5,a5,1466 # 80005e00 <kernelvec>
    8000284e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	174080e7          	jalr	372(ra) # 800019c6 <myproc>
    8000285a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000285c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000285e:	14102773          	csrr	a4,sepc
    80002862:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002864:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002868:	47a1                	li	a5,8
    8000286a:	02f70763          	beq	a4,a5,80002898 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    8000286e:	00000097          	auipc	ra,0x0
    80002872:	f20080e7          	jalr	-224(ra) # 8000278e <devintr>
    80002876:	892a                	mv	s2,a0
    80002878:	c92d                	beqz	a0,800028ea <usertrap+0xba>
  if (killed(p))
    8000287a:	8526                	mv	a0,s1
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	ad2080e7          	jalr	-1326(ra) # 8000234e <killed>
    80002884:	c555                	beqz	a0,80002930 <usertrap+0x100>
    80002886:	a045                	j	80002926 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	a9850513          	addi	a0,a0,-1384 # 80008320 <states.1728+0x58>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cb4080e7          	jalr	-844(ra) # 80000544 <panic>
    if (killed(p))
    80002898:	00000097          	auipc	ra,0x0
    8000289c:	ab6080e7          	jalr	-1354(ra) # 8000234e <killed>
    800028a0:	ed1d                	bnez	a0,800028de <usertrap+0xae>
    p->trapframe->epc += 4;
    800028a2:	6cb8                	ld	a4,88(s1)
    800028a4:	6f1c                	ld	a5,24(a4)
    800028a6:	0791                	addi	a5,a5,4
    800028a8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028aa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028b2:	10079073          	csrw	sstatus,a5
    syscall();
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	330080e7          	jalr	816(ra) # 80002be6 <syscall>
  if (killed(p))
    800028be:	8526                	mv	a0,s1
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	a8e080e7          	jalr	-1394(ra) # 8000234e <killed>
    800028c8:	ed31                	bnez	a0,80002924 <usertrap+0xf4>
  usertrapret();
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	de8080e7          	jalr	-536(ra) # 800026b2 <usertrapret>
}
    800028d2:	60e2                	ld	ra,24(sp)
    800028d4:	6442                	ld	s0,16(sp)
    800028d6:	64a2                	ld	s1,8(sp)
    800028d8:	6902                	ld	s2,0(sp)
    800028da:	6105                	addi	sp,sp,32
    800028dc:	8082                	ret
      exit(-1);
    800028de:	557d                	li	a0,-1
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	8fa080e7          	jalr	-1798(ra) # 800021da <exit>
    800028e8:	bf6d                	j	800028a2 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ea:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028ee:	5890                	lw	a2,48(s1)
    800028f0:	00006517          	auipc	a0,0x6
    800028f4:	a5050513          	addi	a0,a0,-1456 # 80008340 <states.1728+0x78>
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	c96080e7          	jalr	-874(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002900:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002904:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002908:	00006517          	auipc	a0,0x6
    8000290c:	a6850513          	addi	a0,a0,-1432 # 80008370 <states.1728+0xa8>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	c7e080e7          	jalr	-898(ra) # 8000058e <printf>
    setkilled(p);
    80002918:	8526                	mv	a0,s1
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	a08080e7          	jalr	-1528(ra) # 80002322 <setkilled>
    80002922:	bf71                	j	800028be <usertrap+0x8e>
  if (killed(p))
    80002924:	4901                	li	s2,0
    exit(-1);
    80002926:	557d                	li	a0,-1
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	8b2080e7          	jalr	-1870(ra) # 800021da <exit>
  if (which_dev == 2)
    80002930:	4789                	li	a5,2
    80002932:	f8f91ce3          	bne	s2,a5,800028ca <usertrap+0x9a>
    p->completed_clockval = p->completed_clockval + 1;
    80002936:	1744a783          	lw	a5,372(s1)
    8000293a:	2785                	addiw	a5,a5,1
    8000293c:	0007871b          	sext.w	a4,a5
    80002940:	16f4aa23          	sw	a5,372(s1)
    if (p->clockval > 0 && p->clockval <= p->completed_clockval)
    80002944:	1704a783          	lw	a5,368(s1)
    80002948:	04f05663          	blez	a5,80002994 <usertrap+0x164>
    8000294c:	04f74463          	blt	a4,a5,80002994 <usertrap+0x164>
      if (p->is_sigalarm == 0)
    80002950:	16c4a783          	lw	a5,364(s1)
    80002954:	e3a1                	bnez	a5,80002994 <usertrap+0x164>
        p->is_sigalarm = 1;
    80002956:	4785                	li	a5,1
    80002958:	16f4a623          	sw	a5,364(s1)
        p->completed_clockval = 0;
    8000295c:	1604aa23          	sw	zero,372(s1)
        *(p->cpy_trapframe) = *(p->trapframe);
    80002960:	6cb4                	ld	a3,88(s1)
    80002962:	87b6                	mv	a5,a3
    80002964:	1804b703          	ld	a4,384(s1)
    80002968:	12068693          	addi	a3,a3,288
    8000296c:	0007b803          	ld	a6,0(a5)
    80002970:	6788                	ld	a0,8(a5)
    80002972:	6b8c                	ld	a1,16(a5)
    80002974:	6f90                	ld	a2,24(a5)
    80002976:	01073023          	sd	a6,0(a4)
    8000297a:	e708                	sd	a0,8(a4)
    8000297c:	eb0c                	sd	a1,16(a4)
    8000297e:	ef10                	sd	a2,24(a4)
    80002980:	02078793          	addi	a5,a5,32
    80002984:	02070713          	addi	a4,a4,32
    80002988:	fed792e3          	bne	a5,a3,8000296c <usertrap+0x13c>
        p->trapframe->epc = p->handler;
    8000298c:	6cbc                	ld	a5,88(s1)
    8000298e:	1784b703          	ld	a4,376(s1)
    80002992:	ef98                	sd	a4,24(a5)
    yield();
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	6d6080e7          	jalr	1750(ra) # 8000206a <yield>
    8000299c:	b73d                	j	800028ca <usertrap+0x9a>

000000008000299e <kerneltrap>:
{
    8000299e:	7179                	addi	sp,sp,-48
    800029a0:	f406                	sd	ra,40(sp)
    800029a2:	f022                	sd	s0,32(sp)
    800029a4:	ec26                	sd	s1,24(sp)
    800029a6:	e84a                	sd	s2,16(sp)
    800029a8:	e44e                	sd	s3,8(sp)
    800029aa:	e052                	sd	s4,0(sp)
    800029ac:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	018080e7          	jalr	24(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b6:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ba:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029be:	14202a73          	csrr	s4,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800029c2:	10097793          	andi	a5,s2,256
    800029c6:	cb95                	beqz	a5,800029fa <kerneltrap+0x5c>
    800029c8:	84aa                	mv	s1,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ca:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029ce:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800029d0:	ef8d                	bnez	a5,80002a0a <kerneltrap+0x6c>
  if ((which_dev = devintr()) == 0)
    800029d2:	00000097          	auipc	ra,0x0
    800029d6:	dbc080e7          	jalr	-580(ra) # 8000278e <devintr>
    800029da:	c121                	beqz	a0,80002a1a <kerneltrap+0x7c>
  if (which_dev == 2 && p != 0 && p->state == RUNNING)
    800029dc:	4789                	li	a5,2
    800029de:	06f50b63          	beq	a0,a5,80002a54 <kerneltrap+0xb6>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e2:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e6:	10091073          	csrw	sstatus,s2
}
    800029ea:	70a2                	ld	ra,40(sp)
    800029ec:	7402                	ld	s0,32(sp)
    800029ee:	64e2                	ld	s1,24(sp)
    800029f0:	6942                	ld	s2,16(sp)
    800029f2:	69a2                	ld	s3,8(sp)
    800029f4:	6a02                	ld	s4,0(sp)
    800029f6:	6145                	addi	sp,sp,48
    800029f8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	99650513          	addi	a0,a0,-1642 # 80008390 <states.1728+0xc8>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b42080e7          	jalr	-1214(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	9ae50513          	addi	a0,a0,-1618 # 800083b8 <states.1728+0xf0>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b32080e7          	jalr	-1230(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a1a:	85d2                	mv	a1,s4
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	9bc50513          	addi	a0,a0,-1604 # 800083d8 <states.1728+0x110>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b6a080e7          	jalr	-1174(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a2c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a30:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a34:	00006517          	auipc	a0,0x6
    80002a38:	9b450513          	addi	a0,a0,-1612 # 800083e8 <states.1728+0x120>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b52080e7          	jalr	-1198(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	9bc50513          	addi	a0,a0,-1604 # 80008400 <states.1728+0x138>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	af8080e7          	jalr	-1288(ra) # 80000544 <panic>
  if (which_dev == 2 && p != 0 && p->state == RUNNING)
    80002a54:	d4d9                	beqz	s1,800029e2 <kerneltrap+0x44>
    80002a56:	4c98                	lw	a4,24(s1)
    80002a58:	4791                	li	a5,4
    80002a5a:	f8f714e3          	bne	a4,a5,800029e2 <kerneltrap+0x44>
    yield();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	60c080e7          	jalr	1548(ra) # 8000206a <yield>
    80002a66:	bfb5                	j	800029e2 <kerneltrap+0x44>

0000000080002a68 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a68:	1101                	addi	sp,sp,-32
    80002a6a:	ec06                	sd	ra,24(sp)
    80002a6c:	e822                	sd	s0,16(sp)
    80002a6e:	e426                	sd	s1,8(sp)
    80002a70:	1000                	addi	s0,sp,32
    80002a72:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	f52080e7          	jalr	-174(ra) # 800019c6 <myproc>
  switch (n)
    80002a7c:	4795                	li	a5,5
    80002a7e:	0497e163          	bltu	a5,s1,80002ac0 <argraw+0x58>
    80002a82:	048a                	slli	s1,s1,0x2
    80002a84:	00006717          	auipc	a4,0x6
    80002a88:	b4470713          	addi	a4,a4,-1212 # 800085c8 <states.1728+0x300>
    80002a8c:	94ba                	add	s1,s1,a4
    80002a8e:	409c                	lw	a5,0(s1)
    80002a90:	97ba                	add	a5,a5,a4
    80002a92:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002a94:	6d3c                	ld	a5,88(a0)
    80002a96:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a98:	60e2                	ld	ra,24(sp)
    80002a9a:	6442                	ld	s0,16(sp)
    80002a9c:	64a2                	ld	s1,8(sp)
    80002a9e:	6105                	addi	sp,sp,32
    80002aa0:	8082                	ret
    return p->trapframe->a1;
    80002aa2:	6d3c                	ld	a5,88(a0)
    80002aa4:	7fa8                	ld	a0,120(a5)
    80002aa6:	bfcd                	j	80002a98 <argraw+0x30>
    return p->trapframe->a2;
    80002aa8:	6d3c                	ld	a5,88(a0)
    80002aaa:	63c8                	ld	a0,128(a5)
    80002aac:	b7f5                	j	80002a98 <argraw+0x30>
    return p->trapframe->a3;
    80002aae:	6d3c                	ld	a5,88(a0)
    80002ab0:	67c8                	ld	a0,136(a5)
    80002ab2:	b7dd                	j	80002a98 <argraw+0x30>
    return p->trapframe->a4;
    80002ab4:	6d3c                	ld	a5,88(a0)
    80002ab6:	6bc8                	ld	a0,144(a5)
    80002ab8:	b7c5                	j	80002a98 <argraw+0x30>
    return p->trapframe->a5;
    80002aba:	6d3c                	ld	a5,88(a0)
    80002abc:	6fc8                	ld	a0,152(a5)
    80002abe:	bfe9                	j	80002a98 <argraw+0x30>
  panic("argraw");
    80002ac0:	00006517          	auipc	a0,0x6
    80002ac4:	95050513          	addi	a0,a0,-1712 # 80008410 <states.1728+0x148>
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	a7c080e7          	jalr	-1412(ra) # 80000544 <panic>

0000000080002ad0 <fetchaddr>:
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	e426                	sd	s1,8(sp)
    80002ad8:	e04a                	sd	s2,0(sp)
    80002ada:	1000                	addi	s0,sp,32
    80002adc:	84aa                	mv	s1,a0
    80002ade:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	ee6080e7          	jalr	-282(ra) # 800019c6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ae8:	653c                	ld	a5,72(a0)
    80002aea:	02f4f863          	bgeu	s1,a5,80002b1a <fetchaddr+0x4a>
    80002aee:	00848713          	addi	a4,s1,8
    80002af2:	02e7e663          	bltu	a5,a4,80002b1e <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002af6:	46a1                	li	a3,8
    80002af8:	8626                	mv	a2,s1
    80002afa:	85ca                	mv	a1,s2
    80002afc:	6928                	ld	a0,80(a0)
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	c12080e7          	jalr	-1006(ra) # 80001710 <copyin>
    80002b06:	00a03533          	snez	a0,a0
    80002b0a:	40a00533          	neg	a0,a0
}
    80002b0e:	60e2                	ld	ra,24(sp)
    80002b10:	6442                	ld	s0,16(sp)
    80002b12:	64a2                	ld	s1,8(sp)
    80002b14:	6902                	ld	s2,0(sp)
    80002b16:	6105                	addi	sp,sp,32
    80002b18:	8082                	ret
    return -1;
    80002b1a:	557d                	li	a0,-1
    80002b1c:	bfcd                	j	80002b0e <fetchaddr+0x3e>
    80002b1e:	557d                	li	a0,-1
    80002b20:	b7fd                	j	80002b0e <fetchaddr+0x3e>

0000000080002b22 <fetchstr>:
{
    80002b22:	7179                	addi	sp,sp,-48
    80002b24:	f406                	sd	ra,40(sp)
    80002b26:	f022                	sd	s0,32(sp)
    80002b28:	ec26                	sd	s1,24(sp)
    80002b2a:	e84a                	sd	s2,16(sp)
    80002b2c:	e44e                	sd	s3,8(sp)
    80002b2e:	1800                	addi	s0,sp,48
    80002b30:	892a                	mv	s2,a0
    80002b32:	84ae                	mv	s1,a1
    80002b34:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	e90080e7          	jalr	-368(ra) # 800019c6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b3e:	86ce                	mv	a3,s3
    80002b40:	864a                	mv	a2,s2
    80002b42:	85a6                	mv	a1,s1
    80002b44:	6928                	ld	a0,80(a0)
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	c56080e7          	jalr	-938(ra) # 8000179c <copyinstr>
    80002b4e:	00054e63          	bltz	a0,80002b6a <fetchstr+0x48>
  return strlen(buf);
    80002b52:	8526                	mv	a0,s1
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	316080e7          	jalr	790(ra) # 80000e6a <strlen>
}
    80002b5c:	70a2                	ld	ra,40(sp)
    80002b5e:	7402                	ld	s0,32(sp)
    80002b60:	64e2                	ld	s1,24(sp)
    80002b62:	6942                	ld	s2,16(sp)
    80002b64:	69a2                	ld	s3,8(sp)
    80002b66:	6145                	addi	sp,sp,48
    80002b68:	8082                	ret
    return -1;
    80002b6a:	557d                	li	a0,-1
    80002b6c:	bfc5                	j	80002b5c <fetchstr+0x3a>

0000000080002b6e <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002b6e:	1101                	addi	sp,sp,-32
    80002b70:	ec06                	sd	ra,24(sp)
    80002b72:	e822                	sd	s0,16(sp)
    80002b74:	e426                	sd	s1,8(sp)
    80002b76:	1000                	addi	s0,sp,32
    80002b78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	eee080e7          	jalr	-274(ra) # 80002a68 <argraw>
    80002b82:	c088                	sw	a0,0(s1)
}
    80002b84:	60e2                	ld	ra,24(sp)
    80002b86:	6442                	ld	s0,16(sp)
    80002b88:	64a2                	ld	s1,8(sp)
    80002b8a:	6105                	addi	sp,sp,32
    80002b8c:	8082                	ret

0000000080002b8e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002b8e:	1101                	addi	sp,sp,-32
    80002b90:	ec06                	sd	ra,24(sp)
    80002b92:	e822                	sd	s0,16(sp)
    80002b94:	e426                	sd	s1,8(sp)
    80002b96:	1000                	addi	s0,sp,32
    80002b98:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b9a:	00000097          	auipc	ra,0x0
    80002b9e:	ece080e7          	jalr	-306(ra) # 80002a68 <argraw>
    80002ba2:	e088                	sd	a0,0(s1)
}
    80002ba4:	60e2                	ld	ra,24(sp)
    80002ba6:	6442                	ld	s0,16(sp)
    80002ba8:	64a2                	ld	s1,8(sp)
    80002baa:	6105                	addi	sp,sp,32
    80002bac:	8082                	ret

0000000080002bae <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002bae:	7179                	addi	sp,sp,-48
    80002bb0:	f406                	sd	ra,40(sp)
    80002bb2:	f022                	sd	s0,32(sp)
    80002bb4:	ec26                	sd	s1,24(sp)
    80002bb6:	e84a                	sd	s2,16(sp)
    80002bb8:	1800                	addi	s0,sp,48
    80002bba:	84ae                	mv	s1,a1
    80002bbc:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bbe:	fd840593          	addi	a1,s0,-40
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	fcc080e7          	jalr	-52(ra) # 80002b8e <argaddr>
  return fetchstr(addr, buf, max);
    80002bca:	864a                	mv	a2,s2
    80002bcc:	85a6                	mv	a1,s1
    80002bce:	fd843503          	ld	a0,-40(s0)
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	f50080e7          	jalr	-176(ra) # 80002b22 <fetchstr>
}
    80002bda:	70a2                	ld	ra,40(sp)
    80002bdc:	7402                	ld	s0,32(sp)
    80002bde:	64e2                	ld	s1,24(sp)
    80002be0:	6942                	ld	s2,16(sp)
    80002be2:	6145                	addi	sp,sp,48
    80002be4:	8082                	ret

0000000080002be6 <syscall>:
    // [SYS_sigalarm] 0,
    // [SYS_sigreturn] 0,
};

void syscall(void)
{
    80002be6:	7139                	addi	sp,sp,-64
    80002be8:	fc06                	sd	ra,56(sp)
    80002bea:	f822                	sd	s0,48(sp)
    80002bec:	f426                	sd	s1,40(sp)
    80002bee:	f04a                	sd	s2,32(sp)
    80002bf0:	ec4e                	sd	s3,24(sp)
    80002bf2:	e852                	sd	s4,16(sp)
    80002bf4:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	dd0080e7          	jalr	-560(ra) # 800019c6 <myproc>
    80002bfe:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c00:	05853903          	ld	s2,88(a0)
    80002c04:	0a893783          	ld	a5,168(s2)
    80002c08:	0007899b          	sext.w	s3,a5

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002c0c:	37fd                	addiw	a5,a5,-1
    80002c0e:	475d                	li	a4,23
    80002c10:	1af76763          	bltu	a4,a5,80002dbe <syscall+0x1d8>
    80002c14:	00399713          	slli	a4,s3,0x3
    80002c18:	00006797          	auipc	a5,0x6
    80002c1c:	9c878793          	addi	a5,a5,-1592 # 800085e0 <syscalls>
    80002c20:	97ba                	add	a5,a5,a4
    80002c22:	639c                	ld	a5,0(a5)
    80002c24:	18078d63          	beqz	a5,80002dbe <syscall+0x1d8>
  {
    int x = p->trapframe->a0;
    80002c28:	07093a03          	ld	s4,112(s2)

    p->trapframe->a0 = syscalls[num]();
    80002c2c:	9782                	jalr	a5
    80002c2e:	06a93823          	sd	a0,112(s2)

    if (((1 << num) & p->tracy) != 0)
    80002c32:	1684a783          	lw	a5,360(s1)
    80002c36:	4137d7bb          	sraw	a5,a5,s3
    80002c3a:	8b85                	andi	a5,a5,1
    80002c3c:	1a078063          	beqz	a5,80002ddc <syscall+0x1f6>
    int x = p->trapframe->a0;
    80002c40:	000a069b          	sext.w	a3,s4
    {
      if (nargs[num] == 0)
    80002c44:	00299713          	slli	a4,s3,0x2
    80002c48:	00006797          	auipc	a5,0x6
    80002c4c:	de078793          	addi	a5,a5,-544 # 80008a28 <nargs>
    80002c50:	97ba                	add	a5,a5,a4
    80002c52:	439c                	lw	a5,0(a5)
    80002c54:	cfa9                	beqz	a5,80002cae <syscall+0xc8>
      {
        printf("%d: syscall %s (%d) -> %d\n", p->pid, names[num], x, p->trapframe->a0);
      }
      else if (nargs[num] == 1)
    80002c56:	4705                	li	a4,1
    80002c58:	06e78f63          	beq	a5,a4,80002cd6 <syscall+0xf0>
      {
        printf("%d: syscall %s (%d) -> %d\n", p->pid, names[num], x, p->trapframe->a0);
      }
      else if (nargs[num] == 2)
    80002c5c:	4709                	li	a4,2
    80002c5e:	0ae78063          	beq	a5,a4,80002cfe <syscall+0x118>
      {
        printf("%d: syscall %s (%d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a0);
      }
      else if (nargs[num] == 3)
    80002c62:	470d                	li	a4,3
    80002c64:	0ce78263          	beq	a5,a4,80002d28 <syscall+0x142>
      {
        printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0);
      }
      else if (nargs[num] == 4)
    80002c68:	4711                	li	a4,4
    80002c6a:	0ee78663          	beq	a5,a4,80002d56 <syscall+0x170>
      {
        printf("%d: syscall %s (%d %d %d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0);
      }
      else if (nargs[num] == 5)
    80002c6e:	4715                	li	a4,5
    80002c70:	10e78c63          	beq	a5,a4,80002d88 <syscall+0x1a2>
      {
        printf("%d: syscall %s (%d %d %d %d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a4, p->trapframe->a0);
      }
      else
      {
        printf("%d: syscall %s (%d %d %d %d %d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a4, p->trapframe->a5, p->trapframe->a0);
    80002c74:	6cb0                	ld	a2,88(s1)
    80002c76:	09063883          	ld	a7,144(a2)
    80002c7a:	08863803          	ld	a6,136(a2)
    80002c7e:	625c                	ld	a5,128(a2)
    80002c80:	7e38                	ld	a4,120(a2)
    80002c82:	098e                	slli	s3,s3,0x3
    80002c84:	00006597          	auipc	a1,0x6
    80002c88:	da458593          	addi	a1,a1,-604 # 80008a28 <nargs>
    80002c8c:	99ae                	add	s3,s3,a1
    80002c8e:	588c                	lw	a1,48(s1)
    80002c90:	7a28                	ld	a0,112(a2)
    80002c92:	e42a                	sd	a0,8(sp)
    80002c94:	6e50                	ld	a2,152(a2)
    80002c96:	e032                	sd	a2,0(sp)
    80002c98:	0609b603          	ld	a2,96(s3)
    80002c9c:	00006517          	auipc	a0,0x6
    80002ca0:	83450513          	addi	a0,a0,-1996 # 800084d0 <states.1728+0x208>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	8ea080e7          	jalr	-1814(ra) # 8000058e <printf>
    80002cac:	aa05                	j	80002ddc <syscall+0x1f6>
        printf("%d: syscall %s (%d) -> %d\n", p->pid, names[num], x, p->trapframe->a0);
    80002cae:	6cb8                	ld	a4,88(s1)
    80002cb0:	098e                	slli	s3,s3,0x3
    80002cb2:	00006797          	auipc	a5,0x6
    80002cb6:	d7678793          	addi	a5,a5,-650 # 80008a28 <nargs>
    80002cba:	99be                	add	s3,s3,a5
    80002cbc:	7b38                	ld	a4,112(a4)
    80002cbe:	0609b603          	ld	a2,96(s3)
    80002cc2:	588c                	lw	a1,48(s1)
    80002cc4:	00005517          	auipc	a0,0x5
    80002cc8:	75450513          	addi	a0,a0,1876 # 80008418 <states.1728+0x150>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	8c2080e7          	jalr	-1854(ra) # 8000058e <printf>
    80002cd4:	a221                	j	80002ddc <syscall+0x1f6>
        printf("%d: syscall %s (%d) -> %d\n", p->pid, names[num], x, p->trapframe->a0);
    80002cd6:	6cb8                	ld	a4,88(s1)
    80002cd8:	098e                	slli	s3,s3,0x3
    80002cda:	00006797          	auipc	a5,0x6
    80002cde:	d4e78793          	addi	a5,a5,-690 # 80008a28 <nargs>
    80002ce2:	99be                	add	s3,s3,a5
    80002ce4:	7b38                	ld	a4,112(a4)
    80002ce6:	0609b603          	ld	a2,96(s3)
    80002cea:	588c                	lw	a1,48(s1)
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	72c50513          	addi	a0,a0,1836 # 80008418 <states.1728+0x150>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	89a080e7          	jalr	-1894(ra) # 8000058e <printf>
    80002cfc:	a0c5                	j	80002ddc <syscall+0x1f6>
        printf("%d: syscall %s (%d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a0);
    80002cfe:	6cb8                	ld	a4,88(s1)
    80002d00:	098e                	slli	s3,s3,0x3
    80002d02:	00006797          	auipc	a5,0x6
    80002d06:	d2678793          	addi	a5,a5,-730 # 80008a28 <nargs>
    80002d0a:	99be                	add	s3,s3,a5
    80002d0c:	7b3c                	ld	a5,112(a4)
    80002d0e:	7f38                	ld	a4,120(a4)
    80002d10:	0609b603          	ld	a2,96(s3)
    80002d14:	588c                	lw	a1,48(s1)
    80002d16:	00005517          	auipc	a0,0x5
    80002d1a:	72250513          	addi	a0,a0,1826 # 80008438 <states.1728+0x170>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	870080e7          	jalr	-1936(ra) # 8000058e <printf>
    80002d26:	a85d                	j	80002ddc <syscall+0x1f6>
        printf("%d: syscall %s (%d %d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0);
    80002d28:	6cb8                	ld	a4,88(s1)
    80002d2a:	098e                	slli	s3,s3,0x3
    80002d2c:	00006797          	auipc	a5,0x6
    80002d30:	cfc78793          	addi	a5,a5,-772 # 80008a28 <nargs>
    80002d34:	99be                	add	s3,s3,a5
    80002d36:	07073803          	ld	a6,112(a4)
    80002d3a:	635c                	ld	a5,128(a4)
    80002d3c:	7f38                	ld	a4,120(a4)
    80002d3e:	0609b603          	ld	a2,96(s3)
    80002d42:	588c                	lw	a1,48(s1)
    80002d44:	00005517          	auipc	a0,0x5
    80002d48:	71450513          	addi	a0,a0,1812 # 80008458 <states.1728+0x190>
    80002d4c:	ffffe097          	auipc	ra,0xffffe
    80002d50:	842080e7          	jalr	-1982(ra) # 8000058e <printf>
    80002d54:	a061                	j	80002ddc <syscall+0x1f6>
        printf("%d: syscall %s (%d %d %d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0);
    80002d56:	6cb8                	ld	a4,88(s1)
    80002d58:	098e                	slli	s3,s3,0x3
    80002d5a:	00006797          	auipc	a5,0x6
    80002d5e:	cce78793          	addi	a5,a5,-818 # 80008a28 <nargs>
    80002d62:	99be                	add	s3,s3,a5
    80002d64:	07073883          	ld	a7,112(a4)
    80002d68:	08873803          	ld	a6,136(a4)
    80002d6c:	635c                	ld	a5,128(a4)
    80002d6e:	7f38                	ld	a4,120(a4)
    80002d70:	0609b603          	ld	a2,96(s3)
    80002d74:	588c                	lw	a1,48(s1)
    80002d76:	00005517          	auipc	a0,0x5
    80002d7a:	70a50513          	addi	a0,a0,1802 # 80008480 <states.1728+0x1b8>
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	810080e7          	jalr	-2032(ra) # 8000058e <printf>
    80002d86:	a899                	j	80002ddc <syscall+0x1f6>
        printf("%d: syscall %s (%d %d %d %d %d) -> %d\n", p->pid, names[num], x, p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a4, p->trapframe->a0);
    80002d88:	6cb0                	ld	a2,88(s1)
    80002d8a:	09063883          	ld	a7,144(a2)
    80002d8e:	08863803          	ld	a6,136(a2)
    80002d92:	625c                	ld	a5,128(a2)
    80002d94:	7e38                	ld	a4,120(a2)
    80002d96:	098e                	slli	s3,s3,0x3
    80002d98:	00006597          	auipc	a1,0x6
    80002d9c:	c9058593          	addi	a1,a1,-880 # 80008a28 <nargs>
    80002da0:	99ae                	add	s3,s3,a1
    80002da2:	588c                	lw	a1,48(s1)
    80002da4:	7a30                	ld	a2,112(a2)
    80002da6:	e032                	sd	a2,0(sp)
    80002da8:	0609b603          	ld	a2,96(s3)
    80002dac:	00005517          	auipc	a0,0x5
    80002db0:	6fc50513          	addi	a0,a0,1788 # 800084a8 <states.1728+0x1e0>
    80002db4:	ffffd097          	auipc	ra,0xffffd
    80002db8:	7da080e7          	jalr	2010(ra) # 8000058e <printf>
    80002dbc:	a005                	j	80002ddc <syscall+0x1f6>

    // p->tracy=0;
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002dbe:	86ce                	mv	a3,s3
    80002dc0:	15848613          	addi	a2,s1,344
    80002dc4:	588c                	lw	a1,48(s1)
    80002dc6:	00005517          	auipc	a0,0x5
    80002dca:	73a50513          	addi	a0,a0,1850 # 80008500 <states.1728+0x238>
    80002dce:	ffffd097          	auipc	ra,0xffffd
    80002dd2:	7c0080e7          	jalr	1984(ra) # 8000058e <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dd6:	6cbc                	ld	a5,88(s1)
    80002dd8:	577d                	li	a4,-1
    80002dda:	fbb8                	sd	a4,112(a5)
  }
}
    80002ddc:	70e2                	ld	ra,56(sp)
    80002dde:	7442                	ld	s0,48(sp)
    80002de0:	74a2                	ld	s1,40(sp)
    80002de2:	7902                	ld	s2,32(sp)
    80002de4:	69e2                	ld	s3,24(sp)
    80002de6:	6a42                	ld	s4,16(sp)
    80002de8:	6121                	addi	sp,sp,64
    80002dea:	8082                	ret

0000000080002dec <sys_exit>:
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64 sys_exit(void)
{
    80002dec:	1101                	addi	sp,sp,-32
    80002dee:	ec06                	sd	ra,24(sp)
    80002df0:	e822                	sd	s0,16(sp)
    80002df2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002df4:	fec40593          	addi	a1,s0,-20
    80002df8:	4501                	li	a0,0
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	d74080e7          	jalr	-652(ra) # 80002b6e <argint>
  exit(n);
    80002e02:	fec42503          	lw	a0,-20(s0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	3d4080e7          	jalr	980(ra) # 800021da <exit>
  return 0; // not reached
}
    80002e0e:	4501                	li	a0,0
    80002e10:	60e2                	ld	ra,24(sp)
    80002e12:	6442                	ld	s0,16(sp)
    80002e14:	6105                	addi	sp,sp,32
    80002e16:	8082                	ret

0000000080002e18 <sys_getpid>:

uint64 sys_getpid(void)
{
    80002e18:	1141                	addi	sp,sp,-16
    80002e1a:	e406                	sd	ra,8(sp)
    80002e1c:	e022                	sd	s0,0(sp)
    80002e1e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	ba6080e7          	jalr	-1114(ra) # 800019c6 <myproc>
}
    80002e28:	5908                	lw	a0,48(a0)
    80002e2a:	60a2                	ld	ra,8(sp)
    80002e2c:	6402                	ld	s0,0(sp)
    80002e2e:	0141                	addi	sp,sp,16
    80002e30:	8082                	ret

0000000080002e32 <sys_fork>:

uint64 sys_fork(void)
{
    80002e32:	1141                	addi	sp,sp,-16
    80002e34:	e406                	sd	ra,8(sp)
    80002e36:	e022                	sd	s0,0(sp)
    80002e38:	0800                	addi	s0,sp,16
  return fork();
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	f7e080e7          	jalr	-130(ra) # 80001db8 <fork>
}
    80002e42:	60a2                	ld	ra,8(sp)
    80002e44:	6402                	ld	s0,0(sp)
    80002e46:	0141                	addi	sp,sp,16
    80002e48:	8082                	ret

0000000080002e4a <sys_wait>:

uint64 sys_wait(void)
{
    80002e4a:	1101                	addi	sp,sp,-32
    80002e4c:	ec06                	sd	ra,24(sp)
    80002e4e:	e822                	sd	s0,16(sp)
    80002e50:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e52:	fe840593          	addi	a1,s0,-24
    80002e56:	4501                	li	a0,0
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	d36080e7          	jalr	-714(ra) # 80002b8e <argaddr>
  return wait(p);
    80002e60:	fe843503          	ld	a0,-24(s0)
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	51c080e7          	jalr	1308(ra) # 80002380 <wait>
}
    80002e6c:	60e2                	ld	ra,24(sp)
    80002e6e:	6442                	ld	s0,16(sp)
    80002e70:	6105                	addi	sp,sp,32
    80002e72:	8082                	ret

0000000080002e74 <sys_sbrk>:

uint64 sys_sbrk(void)
{
    80002e74:	7179                	addi	sp,sp,-48
    80002e76:	f406                	sd	ra,40(sp)
    80002e78:	f022                	sd	s0,32(sp)
    80002e7a:	ec26                	sd	s1,24(sp)
    80002e7c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e7e:	fdc40593          	addi	a1,s0,-36
    80002e82:	4501                	li	a0,0
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	cea080e7          	jalr	-790(ra) # 80002b6e <argint>
  addr = myproc()->sz;
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	b3a080e7          	jalr	-1222(ra) # 800019c6 <myproc>
    80002e94:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002e96:	fdc42503          	lw	a0,-36(s0)
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	ec2080e7          	jalr	-318(ra) # 80001d5c <growproc>
    80002ea2:	00054863          	bltz	a0,80002eb2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ea6:	8526                	mv	a0,s1
    80002ea8:	70a2                	ld	ra,40(sp)
    80002eaa:	7402                	ld	s0,32(sp)
    80002eac:	64e2                	ld	s1,24(sp)
    80002eae:	6145                	addi	sp,sp,48
    80002eb0:	8082                	ret
    return -1;
    80002eb2:	54fd                	li	s1,-1
    80002eb4:	bfcd                	j	80002ea6 <sys_sbrk+0x32>

0000000080002eb6 <sys_sleep>:

uint64 sys_sleep(void)
{
    80002eb6:	7139                	addi	sp,sp,-64
    80002eb8:	fc06                	sd	ra,56(sp)
    80002eba:	f822                	sd	s0,48(sp)
    80002ebc:	f426                	sd	s1,40(sp)
    80002ebe:	f04a                	sd	s2,32(sp)
    80002ec0:	ec4e                	sd	s3,24(sp)
    80002ec2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ec4:	fcc40593          	addi	a1,s0,-52
    80002ec8:	4501                	li	a0,0
    80002eca:	00000097          	auipc	ra,0x0
    80002ece:	ca4080e7          	jalr	-860(ra) # 80002b6e <argint>
  acquire(&tickslock);
    80002ed2:	00014517          	auipc	a0,0x14
    80002ed6:	53e50513          	addi	a0,a0,1342 # 80017410 <tickslock>
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	d10080e7          	jalr	-752(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002ee2:	00006917          	auipc	s2,0x6
    80002ee6:	c8e92903          	lw	s2,-882(s2) # 80008b70 <ticks>
  while (ticks - ticks0 < n)
    80002eea:	fcc42783          	lw	a5,-52(s0)
    80002eee:	cf9d                	beqz	a5,80002f2c <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ef0:	00014997          	auipc	s3,0x14
    80002ef4:	52098993          	addi	s3,s3,1312 # 80017410 <tickslock>
    80002ef8:	00006497          	auipc	s1,0x6
    80002efc:	c7848493          	addi	s1,s1,-904 # 80008b70 <ticks>
    if (killed(myproc()))
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	ac6080e7          	jalr	-1338(ra) # 800019c6 <myproc>
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	446080e7          	jalr	1094(ra) # 8000234e <killed>
    80002f10:	ed15                	bnez	a0,80002f4c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f12:	85ce                	mv	a1,s3
    80002f14:	8526                	mv	a0,s1
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	190080e7          	jalr	400(ra) # 800020a6 <sleep>
  while (ticks - ticks0 < n)
    80002f1e:	409c                	lw	a5,0(s1)
    80002f20:	412787bb          	subw	a5,a5,s2
    80002f24:	fcc42703          	lw	a4,-52(s0)
    80002f28:	fce7ece3          	bltu	a5,a4,80002f00 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f2c:	00014517          	auipc	a0,0x14
    80002f30:	4e450513          	addi	a0,a0,1252 # 80017410 <tickslock>
    80002f34:	ffffe097          	auipc	ra,0xffffe
    80002f38:	d6a080e7          	jalr	-662(ra) # 80000c9e <release>
  return 0;
    80002f3c:	4501                	li	a0,0
}
    80002f3e:	70e2                	ld	ra,56(sp)
    80002f40:	7442                	ld	s0,48(sp)
    80002f42:	74a2                	ld	s1,40(sp)
    80002f44:	7902                	ld	s2,32(sp)
    80002f46:	69e2                	ld	s3,24(sp)
    80002f48:	6121                	addi	sp,sp,64
    80002f4a:	8082                	ret
      release(&tickslock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	4c450513          	addi	a0,a0,1220 # 80017410 <tickslock>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	d4a080e7          	jalr	-694(ra) # 80000c9e <release>
      return -1;
    80002f5c:	557d                	li	a0,-1
    80002f5e:	b7c5                	j	80002f3e <sys_sleep+0x88>

0000000080002f60 <sys_kill>:

uint64 sys_kill(void)
{
    80002f60:	1101                	addi	sp,sp,-32
    80002f62:	ec06                	sd	ra,24(sp)
    80002f64:	e822                	sd	s0,16(sp)
    80002f66:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f68:	fec40593          	addi	a1,s0,-20
    80002f6c:	4501                	li	a0,0
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	c00080e7          	jalr	-1024(ra) # 80002b6e <argint>
  return kill(pid);
    80002f76:	fec42503          	lw	a0,-20(s0)
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	336080e7          	jalr	822(ra) # 800022b0 <kill>
}
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret

0000000080002f8a <sys_uptime>:

uint64 sys_uptime(void)
{
    80002f8a:	1101                	addi	sp,sp,-32
    80002f8c:	ec06                	sd	ra,24(sp)
    80002f8e:	e822                	sd	s0,16(sp)
    80002f90:	e426                	sd	s1,8(sp)
    80002f92:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f94:	00014517          	auipc	a0,0x14
    80002f98:	47c50513          	addi	a0,a0,1148 # 80017410 <tickslock>
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	c4e080e7          	jalr	-946(ra) # 80000bea <acquire>
  xticks = ticks;
    80002fa4:	00006497          	auipc	s1,0x6
    80002fa8:	bcc4a483          	lw	s1,-1076(s1) # 80008b70 <ticks>
  release(&tickslock);
    80002fac:	00014517          	auipc	a0,0x14
    80002fb0:	46450513          	addi	a0,a0,1124 # 80017410 <tickslock>
    80002fb4:	ffffe097          	auipc	ra,0xffffe
    80002fb8:	cea080e7          	jalr	-790(ra) # 80000c9e <release>
  return xticks;
}
    80002fbc:	02049513          	slli	a0,s1,0x20
    80002fc0:	9101                	srli	a0,a0,0x20
    80002fc2:	60e2                	ld	ra,24(sp)
    80002fc4:	6442                	ld	s0,16(sp)
    80002fc6:	64a2                	ld	s1,8(sp)
    80002fc8:	6105                	addi	sp,sp,32
    80002fca:	8082                	ret

0000000080002fcc <sys_trace>:

uint64 sys_trace(void)
{
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	1000                	addi	s0,sp,32
  int arg;
  argint(0, &arg);
    80002fd4:	fec40593          	addi	a1,s0,-20
    80002fd8:	4501                	li	a0,0
    80002fda:	00000097          	auipc	ra,0x0
    80002fde:	b94080e7          	jalr	-1132(ra) # 80002b6e <argint>
  myproc()->tracy = arg;
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	9e4080e7          	jalr	-1564(ra) # 800019c6 <myproc>
    80002fea:	fec42783          	lw	a5,-20(s0)
    80002fee:	16f52423          	sw	a5,360(a0)
  return 0;
}
    80002ff2:	4501                	li	a0,0
    80002ff4:	60e2                	ld	ra,24(sp)
    80002ff6:	6442                	ld	s0,16(sp)
    80002ff8:	6105                	addi	sp,sp,32
    80002ffa:	8082                	ret

0000000080002ffc <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    80002ffc:	1101                	addi	sp,sp,-32
    80002ffe:	ec06                	sd	ra,24(sp)
    80003000:	e822                	sd	s0,16(sp)
    80003002:	e426                	sd	s1,8(sp)
    80003004:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	9c0080e7          	jalr	-1600(ra) # 800019c6 <myproc>
    8000300e:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->cpy_trapframe, sizeof(*(p->trapframe)));
    80003010:	12000613          	li	a2,288
    80003014:	18053583          	ld	a1,384(a0)
    80003018:	6d28                	ld	a0,88(a0)
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	d2c080e7          	jalr	-724(ra) # 80000d46 <memmove>
  p->completed_clockval = 0;
    80003022:	1604aa23          	sw	zero,372(s1)
  p->is_sigalarm = 0;
    80003026:	1604a623          	sw	zero,364(s1)

  // printf("* handler is %d\n", handler)
  // printf("~ clockval is %d\n", curr_clockval);
  
  usertrapret();
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	688080e7          	jalr	1672(ra) # 800026b2 <usertrapret>
  return 0;
}
    80003032:	4501                	li	a0,0
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	97e080e7          	jalr	-1666(ra) # 800019c6 <myproc>
    80003050:	84aa                	mv	s1,a0
  int curr_clockval;
  argint(0, &curr_clockval);
    80003052:	fdc40593          	addi	a1,s0,-36
    80003056:	4501                	li	a0,0
    80003058:	00000097          	auipc	ra,0x0
    8000305c:	b16080e7          	jalr	-1258(ra) # 80002b6e <argint>

  uint64 curr_handler;
  argaddr(1, &curr_handler);
    80003060:	fd040593          	addi	a1,s0,-48
    80003064:	4505                	li	a0,1
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	b28080e7          	jalr	-1240(ra) # 80002b8e <argaddr>

  // printf("* handler is %d\n", handler)
  // printf("~ clockval is %d\n", curr_clockval);

  p->is_sigalarm = 0;
    8000306e:	1604a623          	sw	zero,364(s1)
  p->completed_clockval = 0;
    80003072:	1604aa23          	sw	zero,372(s1)

  p->clockval = curr_clockval;
    80003076:	fdc42783          	lw	a5,-36(s0)
    8000307a:	16f4a823          	sw	a5,368(s1)
  p->handler = curr_handler; // to store the handler function address
    8000307e:	fd043783          	ld	a5,-48(s0)
    80003082:	16f4bc23          	sd	a5,376(s1)
  return 0;
    80003086:	4501                	li	a0,0
    80003088:	70a2                	ld	ra,40(sp)
    8000308a:	7402                	ld	s0,32(sp)
    8000308c:	64e2                	ld	s1,24(sp)
    8000308e:	6145                	addi	sp,sp,48
    80003090:	8082                	ret

0000000080003092 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003092:	7179                	addi	sp,sp,-48
    80003094:	f406                	sd	ra,40(sp)
    80003096:	f022                	sd	s0,32(sp)
    80003098:	ec26                	sd	s1,24(sp)
    8000309a:	e84a                	sd	s2,16(sp)
    8000309c:	e44e                	sd	s3,8(sp)
    8000309e:	e052                	sd	s4,0(sp)
    800030a0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030a2:	00005597          	auipc	a1,0x5
    800030a6:	60658593          	addi	a1,a1,1542 # 800086a8 <syscalls+0xc8>
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	37e50513          	addi	a0,a0,894 # 80017428 <bcache>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	aa8080e7          	jalr	-1368(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030ba:	0001c797          	auipc	a5,0x1c
    800030be:	36e78793          	addi	a5,a5,878 # 8001f428 <bcache+0x8000>
    800030c2:	0001c717          	auipc	a4,0x1c
    800030c6:	5ce70713          	addi	a4,a4,1486 # 8001f690 <bcache+0x8268>
    800030ca:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030ce:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030d2:	00014497          	auipc	s1,0x14
    800030d6:	36e48493          	addi	s1,s1,878 # 80017440 <bcache+0x18>
    b->next = bcache.head.next;
    800030da:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030dc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030de:	00005a17          	auipc	s4,0x5
    800030e2:	5d2a0a13          	addi	s4,s4,1490 # 800086b0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800030e6:	2b893783          	ld	a5,696(s2)
    800030ea:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030ec:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030f0:	85d2                	mv	a1,s4
    800030f2:	01048513          	addi	a0,s1,16
    800030f6:	00001097          	auipc	ra,0x1
    800030fa:	4c4080e7          	jalr	1220(ra) # 800045ba <initsleeplock>
    bcache.head.next->prev = b;
    800030fe:	2b893783          	ld	a5,696(s2)
    80003102:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003104:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003108:	45848493          	addi	s1,s1,1112
    8000310c:	fd349de3          	bne	s1,s3,800030e6 <binit+0x54>
  }
}
    80003110:	70a2                	ld	ra,40(sp)
    80003112:	7402                	ld	s0,32(sp)
    80003114:	64e2                	ld	s1,24(sp)
    80003116:	6942                	ld	s2,16(sp)
    80003118:	69a2                	ld	s3,8(sp)
    8000311a:	6a02                	ld	s4,0(sp)
    8000311c:	6145                	addi	sp,sp,48
    8000311e:	8082                	ret

0000000080003120 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003120:	7179                	addi	sp,sp,-48
    80003122:	f406                	sd	ra,40(sp)
    80003124:	f022                	sd	s0,32(sp)
    80003126:	ec26                	sd	s1,24(sp)
    80003128:	e84a                	sd	s2,16(sp)
    8000312a:	e44e                	sd	s3,8(sp)
    8000312c:	1800                	addi	s0,sp,48
    8000312e:	89aa                	mv	s3,a0
    80003130:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003132:	00014517          	auipc	a0,0x14
    80003136:	2f650513          	addi	a0,a0,758 # 80017428 <bcache>
    8000313a:	ffffe097          	auipc	ra,0xffffe
    8000313e:	ab0080e7          	jalr	-1360(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003142:	0001c497          	auipc	s1,0x1c
    80003146:	59e4b483          	ld	s1,1438(s1) # 8001f6e0 <bcache+0x82b8>
    8000314a:	0001c797          	auipc	a5,0x1c
    8000314e:	54678793          	addi	a5,a5,1350 # 8001f690 <bcache+0x8268>
    80003152:	02f48f63          	beq	s1,a5,80003190 <bread+0x70>
    80003156:	873e                	mv	a4,a5
    80003158:	a021                	j	80003160 <bread+0x40>
    8000315a:	68a4                	ld	s1,80(s1)
    8000315c:	02e48a63          	beq	s1,a4,80003190 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003160:	449c                	lw	a5,8(s1)
    80003162:	ff379ce3          	bne	a5,s3,8000315a <bread+0x3a>
    80003166:	44dc                	lw	a5,12(s1)
    80003168:	ff2799e3          	bne	a5,s2,8000315a <bread+0x3a>
      b->refcnt++;
    8000316c:	40bc                	lw	a5,64(s1)
    8000316e:	2785                	addiw	a5,a5,1
    80003170:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003172:	00014517          	auipc	a0,0x14
    80003176:	2b650513          	addi	a0,a0,694 # 80017428 <bcache>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	b24080e7          	jalr	-1244(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003182:	01048513          	addi	a0,s1,16
    80003186:	00001097          	auipc	ra,0x1
    8000318a:	46e080e7          	jalr	1134(ra) # 800045f4 <acquiresleep>
      return b;
    8000318e:	a8b9                	j	800031ec <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003190:	0001c497          	auipc	s1,0x1c
    80003194:	5484b483          	ld	s1,1352(s1) # 8001f6d8 <bcache+0x82b0>
    80003198:	0001c797          	auipc	a5,0x1c
    8000319c:	4f878793          	addi	a5,a5,1272 # 8001f690 <bcache+0x8268>
    800031a0:	00f48863          	beq	s1,a5,800031b0 <bread+0x90>
    800031a4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	cf81                	beqz	a5,800031c0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031aa:	64a4                	ld	s1,72(s1)
    800031ac:	fee49de3          	bne	s1,a4,800031a6 <bread+0x86>
  panic("bget: no buffers");
    800031b0:	00005517          	auipc	a0,0x5
    800031b4:	50850513          	addi	a0,a0,1288 # 800086b8 <syscalls+0xd8>
    800031b8:	ffffd097          	auipc	ra,0xffffd
    800031bc:	38c080e7          	jalr	908(ra) # 80000544 <panic>
      b->dev = dev;
    800031c0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031c4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031c8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031cc:	4785                	li	a5,1
    800031ce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031d0:	00014517          	auipc	a0,0x14
    800031d4:	25850513          	addi	a0,a0,600 # 80017428 <bcache>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	ac6080e7          	jalr	-1338(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800031e0:	01048513          	addi	a0,s1,16
    800031e4:	00001097          	auipc	ra,0x1
    800031e8:	410080e7          	jalr	1040(ra) # 800045f4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031ec:	409c                	lw	a5,0(s1)
    800031ee:	cb89                	beqz	a5,80003200 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031f0:	8526                	mv	a0,s1
    800031f2:	70a2                	ld	ra,40(sp)
    800031f4:	7402                	ld	s0,32(sp)
    800031f6:	64e2                	ld	s1,24(sp)
    800031f8:	6942                	ld	s2,16(sp)
    800031fa:	69a2                	ld	s3,8(sp)
    800031fc:	6145                	addi	sp,sp,48
    800031fe:	8082                	ret
    virtio_disk_rw(b, 0);
    80003200:	4581                	li	a1,0
    80003202:	8526                	mv	a0,s1
    80003204:	00003097          	auipc	ra,0x3
    80003208:	fc4080e7          	jalr	-60(ra) # 800061c8 <virtio_disk_rw>
    b->valid = 1;
    8000320c:	4785                	li	a5,1
    8000320e:	c09c                	sw	a5,0(s1)
  return b;
    80003210:	b7c5                	j	800031f0 <bread+0xd0>

0000000080003212 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003212:	1101                	addi	sp,sp,-32
    80003214:	ec06                	sd	ra,24(sp)
    80003216:	e822                	sd	s0,16(sp)
    80003218:	e426                	sd	s1,8(sp)
    8000321a:	1000                	addi	s0,sp,32
    8000321c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000321e:	0541                	addi	a0,a0,16
    80003220:	00001097          	auipc	ra,0x1
    80003224:	46e080e7          	jalr	1134(ra) # 8000468e <holdingsleep>
    80003228:	cd01                	beqz	a0,80003240 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000322a:	4585                	li	a1,1
    8000322c:	8526                	mv	a0,s1
    8000322e:	00003097          	auipc	ra,0x3
    80003232:	f9a080e7          	jalr	-102(ra) # 800061c8 <virtio_disk_rw>
}
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	64a2                	ld	s1,8(sp)
    8000323c:	6105                	addi	sp,sp,32
    8000323e:	8082                	ret
    panic("bwrite");
    80003240:	00005517          	auipc	a0,0x5
    80003244:	49050513          	addi	a0,a0,1168 # 800086d0 <syscalls+0xf0>
    80003248:	ffffd097          	auipc	ra,0xffffd
    8000324c:	2fc080e7          	jalr	764(ra) # 80000544 <panic>

0000000080003250 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003250:	1101                	addi	sp,sp,-32
    80003252:	ec06                	sd	ra,24(sp)
    80003254:	e822                	sd	s0,16(sp)
    80003256:	e426                	sd	s1,8(sp)
    80003258:	e04a                	sd	s2,0(sp)
    8000325a:	1000                	addi	s0,sp,32
    8000325c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000325e:	01050913          	addi	s2,a0,16
    80003262:	854a                	mv	a0,s2
    80003264:	00001097          	auipc	ra,0x1
    80003268:	42a080e7          	jalr	1066(ra) # 8000468e <holdingsleep>
    8000326c:	c92d                	beqz	a0,800032de <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000326e:	854a                	mv	a0,s2
    80003270:	00001097          	auipc	ra,0x1
    80003274:	3da080e7          	jalr	986(ra) # 8000464a <releasesleep>

  acquire(&bcache.lock);
    80003278:	00014517          	auipc	a0,0x14
    8000327c:	1b050513          	addi	a0,a0,432 # 80017428 <bcache>
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	96a080e7          	jalr	-1686(ra) # 80000bea <acquire>
  b->refcnt--;
    80003288:	40bc                	lw	a5,64(s1)
    8000328a:	37fd                	addiw	a5,a5,-1
    8000328c:	0007871b          	sext.w	a4,a5
    80003290:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003292:	eb05                	bnez	a4,800032c2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003294:	68bc                	ld	a5,80(s1)
    80003296:	64b8                	ld	a4,72(s1)
    80003298:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000329a:	64bc                	ld	a5,72(s1)
    8000329c:	68b8                	ld	a4,80(s1)
    8000329e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032a0:	0001c797          	auipc	a5,0x1c
    800032a4:	18878793          	addi	a5,a5,392 # 8001f428 <bcache+0x8000>
    800032a8:	2b87b703          	ld	a4,696(a5)
    800032ac:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032ae:	0001c717          	auipc	a4,0x1c
    800032b2:	3e270713          	addi	a4,a4,994 # 8001f690 <bcache+0x8268>
    800032b6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032b8:	2b87b703          	ld	a4,696(a5)
    800032bc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032be:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032c2:	00014517          	auipc	a0,0x14
    800032c6:	16650513          	addi	a0,a0,358 # 80017428 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	9d4080e7          	jalr	-1580(ra) # 80000c9e <release>
}
    800032d2:	60e2                	ld	ra,24(sp)
    800032d4:	6442                	ld	s0,16(sp)
    800032d6:	64a2                	ld	s1,8(sp)
    800032d8:	6902                	ld	s2,0(sp)
    800032da:	6105                	addi	sp,sp,32
    800032dc:	8082                	ret
    panic("brelse");
    800032de:	00005517          	auipc	a0,0x5
    800032e2:	3fa50513          	addi	a0,a0,1018 # 800086d8 <syscalls+0xf8>
    800032e6:	ffffd097          	auipc	ra,0xffffd
    800032ea:	25e080e7          	jalr	606(ra) # 80000544 <panic>

00000000800032ee <bpin>:

void
bpin(struct buf *b) {
    800032ee:	1101                	addi	sp,sp,-32
    800032f0:	ec06                	sd	ra,24(sp)
    800032f2:	e822                	sd	s0,16(sp)
    800032f4:	e426                	sd	s1,8(sp)
    800032f6:	1000                	addi	s0,sp,32
    800032f8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032fa:	00014517          	auipc	a0,0x14
    800032fe:	12e50513          	addi	a0,a0,302 # 80017428 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	8e8080e7          	jalr	-1816(ra) # 80000bea <acquire>
  b->refcnt++;
    8000330a:	40bc                	lw	a5,64(s1)
    8000330c:	2785                	addiw	a5,a5,1
    8000330e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003310:	00014517          	auipc	a0,0x14
    80003314:	11850513          	addi	a0,a0,280 # 80017428 <bcache>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	986080e7          	jalr	-1658(ra) # 80000c9e <release>
}
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	64a2                	ld	s1,8(sp)
    80003326:	6105                	addi	sp,sp,32
    80003328:	8082                	ret

000000008000332a <bunpin>:

void
bunpin(struct buf *b) {
    8000332a:	1101                	addi	sp,sp,-32
    8000332c:	ec06                	sd	ra,24(sp)
    8000332e:	e822                	sd	s0,16(sp)
    80003330:	e426                	sd	s1,8(sp)
    80003332:	1000                	addi	s0,sp,32
    80003334:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003336:	00014517          	auipc	a0,0x14
    8000333a:	0f250513          	addi	a0,a0,242 # 80017428 <bcache>
    8000333e:	ffffe097          	auipc	ra,0xffffe
    80003342:	8ac080e7          	jalr	-1876(ra) # 80000bea <acquire>
  b->refcnt--;
    80003346:	40bc                	lw	a5,64(s1)
    80003348:	37fd                	addiw	a5,a5,-1
    8000334a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000334c:	00014517          	auipc	a0,0x14
    80003350:	0dc50513          	addi	a0,a0,220 # 80017428 <bcache>
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	94a080e7          	jalr	-1718(ra) # 80000c9e <release>
}
    8000335c:	60e2                	ld	ra,24(sp)
    8000335e:	6442                	ld	s0,16(sp)
    80003360:	64a2                	ld	s1,8(sp)
    80003362:	6105                	addi	sp,sp,32
    80003364:	8082                	ret

0000000080003366 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003366:	1101                	addi	sp,sp,-32
    80003368:	ec06                	sd	ra,24(sp)
    8000336a:	e822                	sd	s0,16(sp)
    8000336c:	e426                	sd	s1,8(sp)
    8000336e:	e04a                	sd	s2,0(sp)
    80003370:	1000                	addi	s0,sp,32
    80003372:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003374:	00d5d59b          	srliw	a1,a1,0xd
    80003378:	0001c797          	auipc	a5,0x1c
    8000337c:	78c7a783          	lw	a5,1932(a5) # 8001fb04 <sb+0x1c>
    80003380:	9dbd                	addw	a1,a1,a5
    80003382:	00000097          	auipc	ra,0x0
    80003386:	d9e080e7          	jalr	-610(ra) # 80003120 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000338a:	0074f713          	andi	a4,s1,7
    8000338e:	4785                	li	a5,1
    80003390:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003394:	14ce                	slli	s1,s1,0x33
    80003396:	90d9                	srli	s1,s1,0x36
    80003398:	00950733          	add	a4,a0,s1
    8000339c:	05874703          	lbu	a4,88(a4)
    800033a0:	00e7f6b3          	and	a3,a5,a4
    800033a4:	c69d                	beqz	a3,800033d2 <bfree+0x6c>
    800033a6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033a8:	94aa                	add	s1,s1,a0
    800033aa:	fff7c793          	not	a5,a5
    800033ae:	8ff9                	and	a5,a5,a4
    800033b0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033b4:	00001097          	auipc	ra,0x1
    800033b8:	120080e7          	jalr	288(ra) # 800044d4 <log_write>
  brelse(bp);
    800033bc:	854a                	mv	a0,s2
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	e92080e7          	jalr	-366(ra) # 80003250 <brelse>
}
    800033c6:	60e2                	ld	ra,24(sp)
    800033c8:	6442                	ld	s0,16(sp)
    800033ca:	64a2                	ld	s1,8(sp)
    800033cc:	6902                	ld	s2,0(sp)
    800033ce:	6105                	addi	sp,sp,32
    800033d0:	8082                	ret
    panic("freeing free block");
    800033d2:	00005517          	auipc	a0,0x5
    800033d6:	30e50513          	addi	a0,a0,782 # 800086e0 <syscalls+0x100>
    800033da:	ffffd097          	auipc	ra,0xffffd
    800033de:	16a080e7          	jalr	362(ra) # 80000544 <panic>

00000000800033e2 <balloc>:
{
    800033e2:	711d                	addi	sp,sp,-96
    800033e4:	ec86                	sd	ra,88(sp)
    800033e6:	e8a2                	sd	s0,80(sp)
    800033e8:	e4a6                	sd	s1,72(sp)
    800033ea:	e0ca                	sd	s2,64(sp)
    800033ec:	fc4e                	sd	s3,56(sp)
    800033ee:	f852                	sd	s4,48(sp)
    800033f0:	f456                	sd	s5,40(sp)
    800033f2:	f05a                	sd	s6,32(sp)
    800033f4:	ec5e                	sd	s7,24(sp)
    800033f6:	e862                	sd	s8,16(sp)
    800033f8:	e466                	sd	s9,8(sp)
    800033fa:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033fc:	0001c797          	auipc	a5,0x1c
    80003400:	6f07a783          	lw	a5,1776(a5) # 8001faec <sb+0x4>
    80003404:	10078163          	beqz	a5,80003506 <balloc+0x124>
    80003408:	8baa                	mv	s7,a0
    8000340a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000340c:	0001cb17          	auipc	s6,0x1c
    80003410:	6dcb0b13          	addi	s6,s6,1756 # 8001fae8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003414:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003416:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003418:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000341a:	6c89                	lui	s9,0x2
    8000341c:	a061                	j	800034a4 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000341e:	974a                	add	a4,a4,s2
    80003420:	8fd5                	or	a5,a5,a3
    80003422:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003426:	854a                	mv	a0,s2
    80003428:	00001097          	auipc	ra,0x1
    8000342c:	0ac080e7          	jalr	172(ra) # 800044d4 <log_write>
        brelse(bp);
    80003430:	854a                	mv	a0,s2
    80003432:	00000097          	auipc	ra,0x0
    80003436:	e1e080e7          	jalr	-482(ra) # 80003250 <brelse>
  bp = bread(dev, bno);
    8000343a:	85a6                	mv	a1,s1
    8000343c:	855e                	mv	a0,s7
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	ce2080e7          	jalr	-798(ra) # 80003120 <bread>
    80003446:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003448:	40000613          	li	a2,1024
    8000344c:	4581                	li	a1,0
    8000344e:	05850513          	addi	a0,a0,88
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	894080e7          	jalr	-1900(ra) # 80000ce6 <memset>
  log_write(bp);
    8000345a:	854a                	mv	a0,s2
    8000345c:	00001097          	auipc	ra,0x1
    80003460:	078080e7          	jalr	120(ra) # 800044d4 <log_write>
  brelse(bp);
    80003464:	854a                	mv	a0,s2
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	dea080e7          	jalr	-534(ra) # 80003250 <brelse>
}
    8000346e:	8526                	mv	a0,s1
    80003470:	60e6                	ld	ra,88(sp)
    80003472:	6446                	ld	s0,80(sp)
    80003474:	64a6                	ld	s1,72(sp)
    80003476:	6906                	ld	s2,64(sp)
    80003478:	79e2                	ld	s3,56(sp)
    8000347a:	7a42                	ld	s4,48(sp)
    8000347c:	7aa2                	ld	s5,40(sp)
    8000347e:	7b02                	ld	s6,32(sp)
    80003480:	6be2                	ld	s7,24(sp)
    80003482:	6c42                	ld	s8,16(sp)
    80003484:	6ca2                	ld	s9,8(sp)
    80003486:	6125                	addi	sp,sp,96
    80003488:	8082                	ret
    brelse(bp);
    8000348a:	854a                	mv	a0,s2
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	dc4080e7          	jalr	-572(ra) # 80003250 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003494:	015c87bb          	addw	a5,s9,s5
    80003498:	00078a9b          	sext.w	s5,a5
    8000349c:	004b2703          	lw	a4,4(s6)
    800034a0:	06eaf363          	bgeu	s5,a4,80003506 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800034a4:	41fad79b          	sraiw	a5,s5,0x1f
    800034a8:	0137d79b          	srliw	a5,a5,0x13
    800034ac:	015787bb          	addw	a5,a5,s5
    800034b0:	40d7d79b          	sraiw	a5,a5,0xd
    800034b4:	01cb2583          	lw	a1,28(s6)
    800034b8:	9dbd                	addw	a1,a1,a5
    800034ba:	855e                	mv	a0,s7
    800034bc:	00000097          	auipc	ra,0x0
    800034c0:	c64080e7          	jalr	-924(ra) # 80003120 <bread>
    800034c4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c6:	004b2503          	lw	a0,4(s6)
    800034ca:	000a849b          	sext.w	s1,s5
    800034ce:	8662                	mv	a2,s8
    800034d0:	faa4fde3          	bgeu	s1,a0,8000348a <balloc+0xa8>
      m = 1 << (bi % 8);
    800034d4:	41f6579b          	sraiw	a5,a2,0x1f
    800034d8:	01d7d69b          	srliw	a3,a5,0x1d
    800034dc:	00c6873b          	addw	a4,a3,a2
    800034e0:	00777793          	andi	a5,a4,7
    800034e4:	9f95                	subw	a5,a5,a3
    800034e6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034ea:	4037571b          	sraiw	a4,a4,0x3
    800034ee:	00e906b3          	add	a3,s2,a4
    800034f2:	0586c683          	lbu	a3,88(a3)
    800034f6:	00d7f5b3          	and	a1,a5,a3
    800034fa:	d195                	beqz	a1,8000341e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fc:	2605                	addiw	a2,a2,1
    800034fe:	2485                	addiw	s1,s1,1
    80003500:	fd4618e3          	bne	a2,s4,800034d0 <balloc+0xee>
    80003504:	b759                	j	8000348a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003506:	00005517          	auipc	a0,0x5
    8000350a:	1f250513          	addi	a0,a0,498 # 800086f8 <syscalls+0x118>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	080080e7          	jalr	128(ra) # 8000058e <printf>
  return 0;
    80003516:	4481                	li	s1,0
    80003518:	bf99                	j	8000346e <balloc+0x8c>

000000008000351a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000351a:	7179                	addi	sp,sp,-48
    8000351c:	f406                	sd	ra,40(sp)
    8000351e:	f022                	sd	s0,32(sp)
    80003520:	ec26                	sd	s1,24(sp)
    80003522:	e84a                	sd	s2,16(sp)
    80003524:	e44e                	sd	s3,8(sp)
    80003526:	e052                	sd	s4,0(sp)
    80003528:	1800                	addi	s0,sp,48
    8000352a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000352c:	47ad                	li	a5,11
    8000352e:	02b7e763          	bltu	a5,a1,8000355c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003532:	02059493          	slli	s1,a1,0x20
    80003536:	9081                	srli	s1,s1,0x20
    80003538:	048a                	slli	s1,s1,0x2
    8000353a:	94aa                	add	s1,s1,a0
    8000353c:	0504a903          	lw	s2,80(s1)
    80003540:	06091e63          	bnez	s2,800035bc <bmap+0xa2>
      addr = balloc(ip->dev);
    80003544:	4108                	lw	a0,0(a0)
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	e9c080e7          	jalr	-356(ra) # 800033e2 <balloc>
    8000354e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003552:	06090563          	beqz	s2,800035bc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003556:	0524a823          	sw	s2,80(s1)
    8000355a:	a08d                	j	800035bc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000355c:	ff45849b          	addiw	s1,a1,-12
    80003560:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003564:	0ff00793          	li	a5,255
    80003568:	08e7e563          	bltu	a5,a4,800035f2 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000356c:	08052903          	lw	s2,128(a0)
    80003570:	00091d63          	bnez	s2,8000358a <bmap+0x70>
      addr = balloc(ip->dev);
    80003574:	4108                	lw	a0,0(a0)
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	e6c080e7          	jalr	-404(ra) # 800033e2 <balloc>
    8000357e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003582:	02090d63          	beqz	s2,800035bc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003586:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000358a:	85ca                	mv	a1,s2
    8000358c:	0009a503          	lw	a0,0(s3)
    80003590:	00000097          	auipc	ra,0x0
    80003594:	b90080e7          	jalr	-1136(ra) # 80003120 <bread>
    80003598:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000359a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000359e:	02049593          	slli	a1,s1,0x20
    800035a2:	9181                	srli	a1,a1,0x20
    800035a4:	058a                	slli	a1,a1,0x2
    800035a6:	00b784b3          	add	s1,a5,a1
    800035aa:	0004a903          	lw	s2,0(s1)
    800035ae:	02090063          	beqz	s2,800035ce <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035b2:	8552                	mv	a0,s4
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	c9c080e7          	jalr	-868(ra) # 80003250 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035bc:	854a                	mv	a0,s2
    800035be:	70a2                	ld	ra,40(sp)
    800035c0:	7402                	ld	s0,32(sp)
    800035c2:	64e2                	ld	s1,24(sp)
    800035c4:	6942                	ld	s2,16(sp)
    800035c6:	69a2                	ld	s3,8(sp)
    800035c8:	6a02                	ld	s4,0(sp)
    800035ca:	6145                	addi	sp,sp,48
    800035cc:	8082                	ret
      addr = balloc(ip->dev);
    800035ce:	0009a503          	lw	a0,0(s3)
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	e10080e7          	jalr	-496(ra) # 800033e2 <balloc>
    800035da:	0005091b          	sext.w	s2,a0
      if(addr){
    800035de:	fc090ae3          	beqz	s2,800035b2 <bmap+0x98>
        a[bn] = addr;
    800035e2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035e6:	8552                	mv	a0,s4
    800035e8:	00001097          	auipc	ra,0x1
    800035ec:	eec080e7          	jalr	-276(ra) # 800044d4 <log_write>
    800035f0:	b7c9                	j	800035b2 <bmap+0x98>
  panic("bmap: out of range");
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	11e50513          	addi	a0,a0,286 # 80008710 <syscalls+0x130>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f4a080e7          	jalr	-182(ra) # 80000544 <panic>

0000000080003602 <iget>:
{
    80003602:	7179                	addi	sp,sp,-48
    80003604:	f406                	sd	ra,40(sp)
    80003606:	f022                	sd	s0,32(sp)
    80003608:	ec26                	sd	s1,24(sp)
    8000360a:	e84a                	sd	s2,16(sp)
    8000360c:	e44e                	sd	s3,8(sp)
    8000360e:	e052                	sd	s4,0(sp)
    80003610:	1800                	addi	s0,sp,48
    80003612:	89aa                	mv	s3,a0
    80003614:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003616:	0001c517          	auipc	a0,0x1c
    8000361a:	4f250513          	addi	a0,a0,1266 # 8001fb08 <itable>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	5cc080e7          	jalr	1484(ra) # 80000bea <acquire>
  empty = 0;
    80003626:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003628:	0001c497          	auipc	s1,0x1c
    8000362c:	4f848493          	addi	s1,s1,1272 # 8001fb20 <itable+0x18>
    80003630:	0001e697          	auipc	a3,0x1e
    80003634:	f8068693          	addi	a3,a3,-128 # 800215b0 <log>
    80003638:	a039                	j	80003646 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000363a:	02090b63          	beqz	s2,80003670 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000363e:	08848493          	addi	s1,s1,136
    80003642:	02d48a63          	beq	s1,a3,80003676 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003646:	449c                	lw	a5,8(s1)
    80003648:	fef059e3          	blez	a5,8000363a <iget+0x38>
    8000364c:	4098                	lw	a4,0(s1)
    8000364e:	ff3716e3          	bne	a4,s3,8000363a <iget+0x38>
    80003652:	40d8                	lw	a4,4(s1)
    80003654:	ff4713e3          	bne	a4,s4,8000363a <iget+0x38>
      ip->ref++;
    80003658:	2785                	addiw	a5,a5,1
    8000365a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000365c:	0001c517          	auipc	a0,0x1c
    80003660:	4ac50513          	addi	a0,a0,1196 # 8001fb08 <itable>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	63a080e7          	jalr	1594(ra) # 80000c9e <release>
      return ip;
    8000366c:	8926                	mv	s2,s1
    8000366e:	a03d                	j	8000369c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003670:	f7f9                	bnez	a5,8000363e <iget+0x3c>
    80003672:	8926                	mv	s2,s1
    80003674:	b7e9                	j	8000363e <iget+0x3c>
  if(empty == 0)
    80003676:	02090c63          	beqz	s2,800036ae <iget+0xac>
  ip->dev = dev;
    8000367a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000367e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003682:	4785                	li	a5,1
    80003684:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003688:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000368c:	0001c517          	auipc	a0,0x1c
    80003690:	47c50513          	addi	a0,a0,1148 # 8001fb08 <itable>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	60a080e7          	jalr	1546(ra) # 80000c9e <release>
}
    8000369c:	854a                	mv	a0,s2
    8000369e:	70a2                	ld	ra,40(sp)
    800036a0:	7402                	ld	s0,32(sp)
    800036a2:	64e2                	ld	s1,24(sp)
    800036a4:	6942                	ld	s2,16(sp)
    800036a6:	69a2                	ld	s3,8(sp)
    800036a8:	6a02                	ld	s4,0(sp)
    800036aa:	6145                	addi	sp,sp,48
    800036ac:	8082                	ret
    panic("iget: no inodes");
    800036ae:	00005517          	auipc	a0,0x5
    800036b2:	07a50513          	addi	a0,a0,122 # 80008728 <syscalls+0x148>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	e8e080e7          	jalr	-370(ra) # 80000544 <panic>

00000000800036be <fsinit>:
fsinit(int dev) {
    800036be:	7179                	addi	sp,sp,-48
    800036c0:	f406                	sd	ra,40(sp)
    800036c2:	f022                	sd	s0,32(sp)
    800036c4:	ec26                	sd	s1,24(sp)
    800036c6:	e84a                	sd	s2,16(sp)
    800036c8:	e44e                	sd	s3,8(sp)
    800036ca:	1800                	addi	s0,sp,48
    800036cc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036ce:	4585                	li	a1,1
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	a50080e7          	jalr	-1456(ra) # 80003120 <bread>
    800036d8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036da:	0001c997          	auipc	s3,0x1c
    800036de:	40e98993          	addi	s3,s3,1038 # 8001fae8 <sb>
    800036e2:	02000613          	li	a2,32
    800036e6:	05850593          	addi	a1,a0,88
    800036ea:	854e                	mv	a0,s3
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	65a080e7          	jalr	1626(ra) # 80000d46 <memmove>
  brelse(bp);
    800036f4:	8526                	mv	a0,s1
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	b5a080e7          	jalr	-1190(ra) # 80003250 <brelse>
  if(sb.magic != FSMAGIC)
    800036fe:	0009a703          	lw	a4,0(s3)
    80003702:	102037b7          	lui	a5,0x10203
    80003706:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000370a:	02f71263          	bne	a4,a5,8000372e <fsinit+0x70>
  initlog(dev, &sb);
    8000370e:	0001c597          	auipc	a1,0x1c
    80003712:	3da58593          	addi	a1,a1,986 # 8001fae8 <sb>
    80003716:	854a                	mv	a0,s2
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	b40080e7          	jalr	-1216(ra) # 80004258 <initlog>
}
    80003720:	70a2                	ld	ra,40(sp)
    80003722:	7402                	ld	s0,32(sp)
    80003724:	64e2                	ld	s1,24(sp)
    80003726:	6942                	ld	s2,16(sp)
    80003728:	69a2                	ld	s3,8(sp)
    8000372a:	6145                	addi	sp,sp,48
    8000372c:	8082                	ret
    panic("invalid file system");
    8000372e:	00005517          	auipc	a0,0x5
    80003732:	00a50513          	addi	a0,a0,10 # 80008738 <syscalls+0x158>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	e0e080e7          	jalr	-498(ra) # 80000544 <panic>

000000008000373e <iinit>:
{
    8000373e:	7179                	addi	sp,sp,-48
    80003740:	f406                	sd	ra,40(sp)
    80003742:	f022                	sd	s0,32(sp)
    80003744:	ec26                	sd	s1,24(sp)
    80003746:	e84a                	sd	s2,16(sp)
    80003748:	e44e                	sd	s3,8(sp)
    8000374a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000374c:	00005597          	auipc	a1,0x5
    80003750:	00458593          	addi	a1,a1,4 # 80008750 <syscalls+0x170>
    80003754:	0001c517          	auipc	a0,0x1c
    80003758:	3b450513          	addi	a0,a0,948 # 8001fb08 <itable>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	3fe080e7          	jalr	1022(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003764:	0001c497          	auipc	s1,0x1c
    80003768:	3cc48493          	addi	s1,s1,972 # 8001fb30 <itable+0x28>
    8000376c:	0001e997          	auipc	s3,0x1e
    80003770:	e5498993          	addi	s3,s3,-428 # 800215c0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003774:	00005917          	auipc	s2,0x5
    80003778:	fe490913          	addi	s2,s2,-28 # 80008758 <syscalls+0x178>
    8000377c:	85ca                	mv	a1,s2
    8000377e:	8526                	mv	a0,s1
    80003780:	00001097          	auipc	ra,0x1
    80003784:	e3a080e7          	jalr	-454(ra) # 800045ba <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003788:	08848493          	addi	s1,s1,136
    8000378c:	ff3498e3          	bne	s1,s3,8000377c <iinit+0x3e>
}
    80003790:	70a2                	ld	ra,40(sp)
    80003792:	7402                	ld	s0,32(sp)
    80003794:	64e2                	ld	s1,24(sp)
    80003796:	6942                	ld	s2,16(sp)
    80003798:	69a2                	ld	s3,8(sp)
    8000379a:	6145                	addi	sp,sp,48
    8000379c:	8082                	ret

000000008000379e <ialloc>:
{
    8000379e:	715d                	addi	sp,sp,-80
    800037a0:	e486                	sd	ra,72(sp)
    800037a2:	e0a2                	sd	s0,64(sp)
    800037a4:	fc26                	sd	s1,56(sp)
    800037a6:	f84a                	sd	s2,48(sp)
    800037a8:	f44e                	sd	s3,40(sp)
    800037aa:	f052                	sd	s4,32(sp)
    800037ac:	ec56                	sd	s5,24(sp)
    800037ae:	e85a                	sd	s6,16(sp)
    800037b0:	e45e                	sd	s7,8(sp)
    800037b2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b4:	0001c717          	auipc	a4,0x1c
    800037b8:	34072703          	lw	a4,832(a4) # 8001faf4 <sb+0xc>
    800037bc:	4785                	li	a5,1
    800037be:	04e7fa63          	bgeu	a5,a4,80003812 <ialloc+0x74>
    800037c2:	8aaa                	mv	s5,a0
    800037c4:	8bae                	mv	s7,a1
    800037c6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037c8:	0001ca17          	auipc	s4,0x1c
    800037cc:	320a0a13          	addi	s4,s4,800 # 8001fae8 <sb>
    800037d0:	00048b1b          	sext.w	s6,s1
    800037d4:	0044d593          	srli	a1,s1,0x4
    800037d8:	018a2783          	lw	a5,24(s4)
    800037dc:	9dbd                	addw	a1,a1,a5
    800037de:	8556                	mv	a0,s5
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	940080e7          	jalr	-1728(ra) # 80003120 <bread>
    800037e8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037ea:	05850993          	addi	s3,a0,88
    800037ee:	00f4f793          	andi	a5,s1,15
    800037f2:	079a                	slli	a5,a5,0x6
    800037f4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037f6:	00099783          	lh	a5,0(s3)
    800037fa:	c3a1                	beqz	a5,8000383a <ialloc+0x9c>
    brelse(bp);
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	a54080e7          	jalr	-1452(ra) # 80003250 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003804:	0485                	addi	s1,s1,1
    80003806:	00ca2703          	lw	a4,12(s4)
    8000380a:	0004879b          	sext.w	a5,s1
    8000380e:	fce7e1e3          	bltu	a5,a4,800037d0 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003812:	00005517          	auipc	a0,0x5
    80003816:	f4e50513          	addi	a0,a0,-178 # 80008760 <syscalls+0x180>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	d74080e7          	jalr	-652(ra) # 8000058e <printf>
  return 0;
    80003822:	4501                	li	a0,0
}
    80003824:	60a6                	ld	ra,72(sp)
    80003826:	6406                	ld	s0,64(sp)
    80003828:	74e2                	ld	s1,56(sp)
    8000382a:	7942                	ld	s2,48(sp)
    8000382c:	79a2                	ld	s3,40(sp)
    8000382e:	7a02                	ld	s4,32(sp)
    80003830:	6ae2                	ld	s5,24(sp)
    80003832:	6b42                	ld	s6,16(sp)
    80003834:	6ba2                	ld	s7,8(sp)
    80003836:	6161                	addi	sp,sp,80
    80003838:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000383a:	04000613          	li	a2,64
    8000383e:	4581                	li	a1,0
    80003840:	854e                	mv	a0,s3
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	4a4080e7          	jalr	1188(ra) # 80000ce6 <memset>
      dip->type = type;
    8000384a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000384e:	854a                	mv	a0,s2
    80003850:	00001097          	auipc	ra,0x1
    80003854:	c84080e7          	jalr	-892(ra) # 800044d4 <log_write>
      brelse(bp);
    80003858:	854a                	mv	a0,s2
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	9f6080e7          	jalr	-1546(ra) # 80003250 <brelse>
      return iget(dev, inum);
    80003862:	85da                	mv	a1,s6
    80003864:	8556                	mv	a0,s5
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	d9c080e7          	jalr	-612(ra) # 80003602 <iget>
    8000386e:	bf5d                	j	80003824 <ialloc+0x86>

0000000080003870 <iupdate>:
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	e04a                	sd	s2,0(sp)
    8000387a:	1000                	addi	s0,sp,32
    8000387c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000387e:	415c                	lw	a5,4(a0)
    80003880:	0047d79b          	srliw	a5,a5,0x4
    80003884:	0001c597          	auipc	a1,0x1c
    80003888:	27c5a583          	lw	a1,636(a1) # 8001fb00 <sb+0x18>
    8000388c:	9dbd                	addw	a1,a1,a5
    8000388e:	4108                	lw	a0,0(a0)
    80003890:	00000097          	auipc	ra,0x0
    80003894:	890080e7          	jalr	-1904(ra) # 80003120 <bread>
    80003898:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000389a:	05850793          	addi	a5,a0,88
    8000389e:	40c8                	lw	a0,4(s1)
    800038a0:	893d                	andi	a0,a0,15
    800038a2:	051a                	slli	a0,a0,0x6
    800038a4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038a6:	04449703          	lh	a4,68(s1)
    800038aa:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038ae:	04649703          	lh	a4,70(s1)
    800038b2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038b6:	04849703          	lh	a4,72(s1)
    800038ba:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038be:	04a49703          	lh	a4,74(s1)
    800038c2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038c6:	44f8                	lw	a4,76(s1)
    800038c8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038ca:	03400613          	li	a2,52
    800038ce:	05048593          	addi	a1,s1,80
    800038d2:	0531                	addi	a0,a0,12
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	472080e7          	jalr	1138(ra) # 80000d46 <memmove>
  log_write(bp);
    800038dc:	854a                	mv	a0,s2
    800038de:	00001097          	auipc	ra,0x1
    800038e2:	bf6080e7          	jalr	-1034(ra) # 800044d4 <log_write>
  brelse(bp);
    800038e6:	854a                	mv	a0,s2
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	968080e7          	jalr	-1688(ra) # 80003250 <brelse>
}
    800038f0:	60e2                	ld	ra,24(sp)
    800038f2:	6442                	ld	s0,16(sp)
    800038f4:	64a2                	ld	s1,8(sp)
    800038f6:	6902                	ld	s2,0(sp)
    800038f8:	6105                	addi	sp,sp,32
    800038fa:	8082                	ret

00000000800038fc <idup>:
{
    800038fc:	1101                	addi	sp,sp,-32
    800038fe:	ec06                	sd	ra,24(sp)
    80003900:	e822                	sd	s0,16(sp)
    80003902:	e426                	sd	s1,8(sp)
    80003904:	1000                	addi	s0,sp,32
    80003906:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003908:	0001c517          	auipc	a0,0x1c
    8000390c:	20050513          	addi	a0,a0,512 # 8001fb08 <itable>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	2da080e7          	jalr	730(ra) # 80000bea <acquire>
  ip->ref++;
    80003918:	449c                	lw	a5,8(s1)
    8000391a:	2785                	addiw	a5,a5,1
    8000391c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000391e:	0001c517          	auipc	a0,0x1c
    80003922:	1ea50513          	addi	a0,a0,490 # 8001fb08 <itable>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	378080e7          	jalr	888(ra) # 80000c9e <release>
}
    8000392e:	8526                	mv	a0,s1
    80003930:	60e2                	ld	ra,24(sp)
    80003932:	6442                	ld	s0,16(sp)
    80003934:	64a2                	ld	s1,8(sp)
    80003936:	6105                	addi	sp,sp,32
    80003938:	8082                	ret

000000008000393a <ilock>:
{
    8000393a:	1101                	addi	sp,sp,-32
    8000393c:	ec06                	sd	ra,24(sp)
    8000393e:	e822                	sd	s0,16(sp)
    80003940:	e426                	sd	s1,8(sp)
    80003942:	e04a                	sd	s2,0(sp)
    80003944:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003946:	c115                	beqz	a0,8000396a <ilock+0x30>
    80003948:	84aa                	mv	s1,a0
    8000394a:	451c                	lw	a5,8(a0)
    8000394c:	00f05f63          	blez	a5,8000396a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003950:	0541                	addi	a0,a0,16
    80003952:	00001097          	auipc	ra,0x1
    80003956:	ca2080e7          	jalr	-862(ra) # 800045f4 <acquiresleep>
  if(ip->valid == 0){
    8000395a:	40bc                	lw	a5,64(s1)
    8000395c:	cf99                	beqz	a5,8000397a <ilock+0x40>
}
    8000395e:	60e2                	ld	ra,24(sp)
    80003960:	6442                	ld	s0,16(sp)
    80003962:	64a2                	ld	s1,8(sp)
    80003964:	6902                	ld	s2,0(sp)
    80003966:	6105                	addi	sp,sp,32
    80003968:	8082                	ret
    panic("ilock");
    8000396a:	00005517          	auipc	a0,0x5
    8000396e:	e0e50513          	addi	a0,a0,-498 # 80008778 <syscalls+0x198>
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	bd2080e7          	jalr	-1070(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000397a:	40dc                	lw	a5,4(s1)
    8000397c:	0047d79b          	srliw	a5,a5,0x4
    80003980:	0001c597          	auipc	a1,0x1c
    80003984:	1805a583          	lw	a1,384(a1) # 8001fb00 <sb+0x18>
    80003988:	9dbd                	addw	a1,a1,a5
    8000398a:	4088                	lw	a0,0(s1)
    8000398c:	fffff097          	auipc	ra,0xfffff
    80003990:	794080e7          	jalr	1940(ra) # 80003120 <bread>
    80003994:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003996:	05850593          	addi	a1,a0,88
    8000399a:	40dc                	lw	a5,4(s1)
    8000399c:	8bbd                	andi	a5,a5,15
    8000399e:	079a                	slli	a5,a5,0x6
    800039a0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039a2:	00059783          	lh	a5,0(a1)
    800039a6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039aa:	00259783          	lh	a5,2(a1)
    800039ae:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039b2:	00459783          	lh	a5,4(a1)
    800039b6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039ba:	00659783          	lh	a5,6(a1)
    800039be:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039c2:	459c                	lw	a5,8(a1)
    800039c4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039c6:	03400613          	li	a2,52
    800039ca:	05b1                	addi	a1,a1,12
    800039cc:	05048513          	addi	a0,s1,80
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	376080e7          	jalr	886(ra) # 80000d46 <memmove>
    brelse(bp);
    800039d8:	854a                	mv	a0,s2
    800039da:	00000097          	auipc	ra,0x0
    800039de:	876080e7          	jalr	-1930(ra) # 80003250 <brelse>
    ip->valid = 1;
    800039e2:	4785                	li	a5,1
    800039e4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039e6:	04449783          	lh	a5,68(s1)
    800039ea:	fbb5                	bnez	a5,8000395e <ilock+0x24>
      panic("ilock: no type");
    800039ec:	00005517          	auipc	a0,0x5
    800039f0:	d9450513          	addi	a0,a0,-620 # 80008780 <syscalls+0x1a0>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	b50080e7          	jalr	-1200(ra) # 80000544 <panic>

00000000800039fc <iunlock>:
{
    800039fc:	1101                	addi	sp,sp,-32
    800039fe:	ec06                	sd	ra,24(sp)
    80003a00:	e822                	sd	s0,16(sp)
    80003a02:	e426                	sd	s1,8(sp)
    80003a04:	e04a                	sd	s2,0(sp)
    80003a06:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a08:	c905                	beqz	a0,80003a38 <iunlock+0x3c>
    80003a0a:	84aa                	mv	s1,a0
    80003a0c:	01050913          	addi	s2,a0,16
    80003a10:	854a                	mv	a0,s2
    80003a12:	00001097          	auipc	ra,0x1
    80003a16:	c7c080e7          	jalr	-900(ra) # 8000468e <holdingsleep>
    80003a1a:	cd19                	beqz	a0,80003a38 <iunlock+0x3c>
    80003a1c:	449c                	lw	a5,8(s1)
    80003a1e:	00f05d63          	blez	a5,80003a38 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a22:	854a                	mv	a0,s2
    80003a24:	00001097          	auipc	ra,0x1
    80003a28:	c26080e7          	jalr	-986(ra) # 8000464a <releasesleep>
}
    80003a2c:	60e2                	ld	ra,24(sp)
    80003a2e:	6442                	ld	s0,16(sp)
    80003a30:	64a2                	ld	s1,8(sp)
    80003a32:	6902                	ld	s2,0(sp)
    80003a34:	6105                	addi	sp,sp,32
    80003a36:	8082                	ret
    panic("iunlock");
    80003a38:	00005517          	auipc	a0,0x5
    80003a3c:	d5850513          	addi	a0,a0,-680 # 80008790 <syscalls+0x1b0>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	b04080e7          	jalr	-1276(ra) # 80000544 <panic>

0000000080003a48 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a48:	7179                	addi	sp,sp,-48
    80003a4a:	f406                	sd	ra,40(sp)
    80003a4c:	f022                	sd	s0,32(sp)
    80003a4e:	ec26                	sd	s1,24(sp)
    80003a50:	e84a                	sd	s2,16(sp)
    80003a52:	e44e                	sd	s3,8(sp)
    80003a54:	e052                	sd	s4,0(sp)
    80003a56:	1800                	addi	s0,sp,48
    80003a58:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a5a:	05050493          	addi	s1,a0,80
    80003a5e:	08050913          	addi	s2,a0,128
    80003a62:	a021                	j	80003a6a <itrunc+0x22>
    80003a64:	0491                	addi	s1,s1,4
    80003a66:	01248d63          	beq	s1,s2,80003a80 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a6a:	408c                	lw	a1,0(s1)
    80003a6c:	dde5                	beqz	a1,80003a64 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a6e:	0009a503          	lw	a0,0(s3)
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	8f4080e7          	jalr	-1804(ra) # 80003366 <bfree>
      ip->addrs[i] = 0;
    80003a7a:	0004a023          	sw	zero,0(s1)
    80003a7e:	b7dd                	j	80003a64 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a80:	0809a583          	lw	a1,128(s3)
    80003a84:	e185                	bnez	a1,80003aa4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a86:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a8a:	854e                	mv	a0,s3
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	de4080e7          	jalr	-540(ra) # 80003870 <iupdate>
}
    80003a94:	70a2                	ld	ra,40(sp)
    80003a96:	7402                	ld	s0,32(sp)
    80003a98:	64e2                	ld	s1,24(sp)
    80003a9a:	6942                	ld	s2,16(sp)
    80003a9c:	69a2                	ld	s3,8(sp)
    80003a9e:	6a02                	ld	s4,0(sp)
    80003aa0:	6145                	addi	sp,sp,48
    80003aa2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aa4:	0009a503          	lw	a0,0(s3)
    80003aa8:	fffff097          	auipc	ra,0xfffff
    80003aac:	678080e7          	jalr	1656(ra) # 80003120 <bread>
    80003ab0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ab2:	05850493          	addi	s1,a0,88
    80003ab6:	45850913          	addi	s2,a0,1112
    80003aba:	a811                	j	80003ace <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003abc:	0009a503          	lw	a0,0(s3)
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	8a6080e7          	jalr	-1882(ra) # 80003366 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ac8:	0491                	addi	s1,s1,4
    80003aca:	01248563          	beq	s1,s2,80003ad4 <itrunc+0x8c>
      if(a[j])
    80003ace:	408c                	lw	a1,0(s1)
    80003ad0:	dde5                	beqz	a1,80003ac8 <itrunc+0x80>
    80003ad2:	b7ed                	j	80003abc <itrunc+0x74>
    brelse(bp);
    80003ad4:	8552                	mv	a0,s4
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	77a080e7          	jalr	1914(ra) # 80003250 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ade:	0809a583          	lw	a1,128(s3)
    80003ae2:	0009a503          	lw	a0,0(s3)
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	880080e7          	jalr	-1920(ra) # 80003366 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003aee:	0809a023          	sw	zero,128(s3)
    80003af2:	bf51                	j	80003a86 <itrunc+0x3e>

0000000080003af4 <iput>:
{
    80003af4:	1101                	addi	sp,sp,-32
    80003af6:	ec06                	sd	ra,24(sp)
    80003af8:	e822                	sd	s0,16(sp)
    80003afa:	e426                	sd	s1,8(sp)
    80003afc:	e04a                	sd	s2,0(sp)
    80003afe:	1000                	addi	s0,sp,32
    80003b00:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b02:	0001c517          	auipc	a0,0x1c
    80003b06:	00650513          	addi	a0,a0,6 # 8001fb08 <itable>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	0e0080e7          	jalr	224(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b12:	4498                	lw	a4,8(s1)
    80003b14:	4785                	li	a5,1
    80003b16:	02f70363          	beq	a4,a5,80003b3c <iput+0x48>
  ip->ref--;
    80003b1a:	449c                	lw	a5,8(s1)
    80003b1c:	37fd                	addiw	a5,a5,-1
    80003b1e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b20:	0001c517          	auipc	a0,0x1c
    80003b24:	fe850513          	addi	a0,a0,-24 # 8001fb08 <itable>
    80003b28:	ffffd097          	auipc	ra,0xffffd
    80003b2c:	176080e7          	jalr	374(ra) # 80000c9e <release>
}
    80003b30:	60e2                	ld	ra,24(sp)
    80003b32:	6442                	ld	s0,16(sp)
    80003b34:	64a2                	ld	s1,8(sp)
    80003b36:	6902                	ld	s2,0(sp)
    80003b38:	6105                	addi	sp,sp,32
    80003b3a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b3c:	40bc                	lw	a5,64(s1)
    80003b3e:	dff1                	beqz	a5,80003b1a <iput+0x26>
    80003b40:	04a49783          	lh	a5,74(s1)
    80003b44:	fbf9                	bnez	a5,80003b1a <iput+0x26>
    acquiresleep(&ip->lock);
    80003b46:	01048913          	addi	s2,s1,16
    80003b4a:	854a                	mv	a0,s2
    80003b4c:	00001097          	auipc	ra,0x1
    80003b50:	aa8080e7          	jalr	-1368(ra) # 800045f4 <acquiresleep>
    release(&itable.lock);
    80003b54:	0001c517          	auipc	a0,0x1c
    80003b58:	fb450513          	addi	a0,a0,-76 # 8001fb08 <itable>
    80003b5c:	ffffd097          	auipc	ra,0xffffd
    80003b60:	142080e7          	jalr	322(ra) # 80000c9e <release>
    itrunc(ip);
    80003b64:	8526                	mv	a0,s1
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	ee2080e7          	jalr	-286(ra) # 80003a48 <itrunc>
    ip->type = 0;
    80003b6e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b72:	8526                	mv	a0,s1
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	cfc080e7          	jalr	-772(ra) # 80003870 <iupdate>
    ip->valid = 0;
    80003b7c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b80:	854a                	mv	a0,s2
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	ac8080e7          	jalr	-1336(ra) # 8000464a <releasesleep>
    acquire(&itable.lock);
    80003b8a:	0001c517          	auipc	a0,0x1c
    80003b8e:	f7e50513          	addi	a0,a0,-130 # 8001fb08 <itable>
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	058080e7          	jalr	88(ra) # 80000bea <acquire>
    80003b9a:	b741                	j	80003b1a <iput+0x26>

0000000080003b9c <iunlockput>:
{
    80003b9c:	1101                	addi	sp,sp,-32
    80003b9e:	ec06                	sd	ra,24(sp)
    80003ba0:	e822                	sd	s0,16(sp)
    80003ba2:	e426                	sd	s1,8(sp)
    80003ba4:	1000                	addi	s0,sp,32
    80003ba6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	e54080e7          	jalr	-428(ra) # 800039fc <iunlock>
  iput(ip);
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	f42080e7          	jalr	-190(ra) # 80003af4 <iput>
}
    80003bba:	60e2                	ld	ra,24(sp)
    80003bbc:	6442                	ld	s0,16(sp)
    80003bbe:	64a2                	ld	s1,8(sp)
    80003bc0:	6105                	addi	sp,sp,32
    80003bc2:	8082                	ret

0000000080003bc4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bc4:	1141                	addi	sp,sp,-16
    80003bc6:	e422                	sd	s0,8(sp)
    80003bc8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bca:	411c                	lw	a5,0(a0)
    80003bcc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bce:	415c                	lw	a5,4(a0)
    80003bd0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bd2:	04451783          	lh	a5,68(a0)
    80003bd6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bda:	04a51783          	lh	a5,74(a0)
    80003bde:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003be2:	04c56783          	lwu	a5,76(a0)
    80003be6:	e99c                	sd	a5,16(a1)
}
    80003be8:	6422                	ld	s0,8(sp)
    80003bea:	0141                	addi	sp,sp,16
    80003bec:	8082                	ret

0000000080003bee <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bee:	457c                	lw	a5,76(a0)
    80003bf0:	0ed7e963          	bltu	a5,a3,80003ce2 <readi+0xf4>
{
    80003bf4:	7159                	addi	sp,sp,-112
    80003bf6:	f486                	sd	ra,104(sp)
    80003bf8:	f0a2                	sd	s0,96(sp)
    80003bfa:	eca6                	sd	s1,88(sp)
    80003bfc:	e8ca                	sd	s2,80(sp)
    80003bfe:	e4ce                	sd	s3,72(sp)
    80003c00:	e0d2                	sd	s4,64(sp)
    80003c02:	fc56                	sd	s5,56(sp)
    80003c04:	f85a                	sd	s6,48(sp)
    80003c06:	f45e                	sd	s7,40(sp)
    80003c08:	f062                	sd	s8,32(sp)
    80003c0a:	ec66                	sd	s9,24(sp)
    80003c0c:	e86a                	sd	s10,16(sp)
    80003c0e:	e46e                	sd	s11,8(sp)
    80003c10:	1880                	addi	s0,sp,112
    80003c12:	8b2a                	mv	s6,a0
    80003c14:	8bae                	mv	s7,a1
    80003c16:	8a32                	mv	s4,a2
    80003c18:	84b6                	mv	s1,a3
    80003c1a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c1c:	9f35                	addw	a4,a4,a3
    return 0;
    80003c1e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c20:	0ad76063          	bltu	a4,a3,80003cc0 <readi+0xd2>
  if(off + n > ip->size)
    80003c24:	00e7f463          	bgeu	a5,a4,80003c2c <readi+0x3e>
    n = ip->size - off;
    80003c28:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2c:	0a0a8963          	beqz	s5,80003cde <readi+0xf0>
    80003c30:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c32:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c36:	5c7d                	li	s8,-1
    80003c38:	a82d                	j	80003c72 <readi+0x84>
    80003c3a:	020d1d93          	slli	s11,s10,0x20
    80003c3e:	020ddd93          	srli	s11,s11,0x20
    80003c42:	05890613          	addi	a2,s2,88
    80003c46:	86ee                	mv	a3,s11
    80003c48:	963a                	add	a2,a2,a4
    80003c4a:	85d2                	mv	a1,s4
    80003c4c:	855e                	mv	a0,s7
    80003c4e:	fffff097          	auipc	ra,0xfffff
    80003c52:	860080e7          	jalr	-1952(ra) # 800024ae <either_copyout>
    80003c56:	05850d63          	beq	a0,s8,80003cb0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c5a:	854a                	mv	a0,s2
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	5f4080e7          	jalr	1524(ra) # 80003250 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c64:	013d09bb          	addw	s3,s10,s3
    80003c68:	009d04bb          	addw	s1,s10,s1
    80003c6c:	9a6e                	add	s4,s4,s11
    80003c6e:	0559f763          	bgeu	s3,s5,80003cbc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c72:	00a4d59b          	srliw	a1,s1,0xa
    80003c76:	855a                	mv	a0,s6
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	8a2080e7          	jalr	-1886(ra) # 8000351a <bmap>
    80003c80:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c84:	cd85                	beqz	a1,80003cbc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c86:	000b2503          	lw	a0,0(s6)
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	496080e7          	jalr	1174(ra) # 80003120 <bread>
    80003c92:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c94:	3ff4f713          	andi	a4,s1,1023
    80003c98:	40ec87bb          	subw	a5,s9,a4
    80003c9c:	413a86bb          	subw	a3,s5,s3
    80003ca0:	8d3e                	mv	s10,a5
    80003ca2:	2781                	sext.w	a5,a5
    80003ca4:	0006861b          	sext.w	a2,a3
    80003ca8:	f8f679e3          	bgeu	a2,a5,80003c3a <readi+0x4c>
    80003cac:	8d36                	mv	s10,a3
    80003cae:	b771                	j	80003c3a <readi+0x4c>
      brelse(bp);
    80003cb0:	854a                	mv	a0,s2
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	59e080e7          	jalr	1438(ra) # 80003250 <brelse>
      tot = -1;
    80003cba:	59fd                	li	s3,-1
  }
  return tot;
    80003cbc:	0009851b          	sext.w	a0,s3
}
    80003cc0:	70a6                	ld	ra,104(sp)
    80003cc2:	7406                	ld	s0,96(sp)
    80003cc4:	64e6                	ld	s1,88(sp)
    80003cc6:	6946                	ld	s2,80(sp)
    80003cc8:	69a6                	ld	s3,72(sp)
    80003cca:	6a06                	ld	s4,64(sp)
    80003ccc:	7ae2                	ld	s5,56(sp)
    80003cce:	7b42                	ld	s6,48(sp)
    80003cd0:	7ba2                	ld	s7,40(sp)
    80003cd2:	7c02                	ld	s8,32(sp)
    80003cd4:	6ce2                	ld	s9,24(sp)
    80003cd6:	6d42                	ld	s10,16(sp)
    80003cd8:	6da2                	ld	s11,8(sp)
    80003cda:	6165                	addi	sp,sp,112
    80003cdc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cde:	89d6                	mv	s3,s5
    80003ce0:	bff1                	j	80003cbc <readi+0xce>
    return 0;
    80003ce2:	4501                	li	a0,0
}
    80003ce4:	8082                	ret

0000000080003ce6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ce6:	457c                	lw	a5,76(a0)
    80003ce8:	10d7e863          	bltu	a5,a3,80003df8 <writei+0x112>
{
    80003cec:	7159                	addi	sp,sp,-112
    80003cee:	f486                	sd	ra,104(sp)
    80003cf0:	f0a2                	sd	s0,96(sp)
    80003cf2:	eca6                	sd	s1,88(sp)
    80003cf4:	e8ca                	sd	s2,80(sp)
    80003cf6:	e4ce                	sd	s3,72(sp)
    80003cf8:	e0d2                	sd	s4,64(sp)
    80003cfa:	fc56                	sd	s5,56(sp)
    80003cfc:	f85a                	sd	s6,48(sp)
    80003cfe:	f45e                	sd	s7,40(sp)
    80003d00:	f062                	sd	s8,32(sp)
    80003d02:	ec66                	sd	s9,24(sp)
    80003d04:	e86a                	sd	s10,16(sp)
    80003d06:	e46e                	sd	s11,8(sp)
    80003d08:	1880                	addi	s0,sp,112
    80003d0a:	8aaa                	mv	s5,a0
    80003d0c:	8bae                	mv	s7,a1
    80003d0e:	8a32                	mv	s4,a2
    80003d10:	8936                	mv	s2,a3
    80003d12:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d14:	00e687bb          	addw	a5,a3,a4
    80003d18:	0ed7e263          	bltu	a5,a3,80003dfc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d1c:	00043737          	lui	a4,0x43
    80003d20:	0ef76063          	bltu	a4,a5,80003e00 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d24:	0c0b0863          	beqz	s6,80003df4 <writei+0x10e>
    80003d28:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d2e:	5c7d                	li	s8,-1
    80003d30:	a091                	j	80003d74 <writei+0x8e>
    80003d32:	020d1d93          	slli	s11,s10,0x20
    80003d36:	020ddd93          	srli	s11,s11,0x20
    80003d3a:	05848513          	addi	a0,s1,88
    80003d3e:	86ee                	mv	a3,s11
    80003d40:	8652                	mv	a2,s4
    80003d42:	85de                	mv	a1,s7
    80003d44:	953a                	add	a0,a0,a4
    80003d46:	ffffe097          	auipc	ra,0xffffe
    80003d4a:	7be080e7          	jalr	1982(ra) # 80002504 <either_copyin>
    80003d4e:	07850263          	beq	a0,s8,80003db2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d52:	8526                	mv	a0,s1
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	780080e7          	jalr	1920(ra) # 800044d4 <log_write>
    brelse(bp);
    80003d5c:	8526                	mv	a0,s1
    80003d5e:	fffff097          	auipc	ra,0xfffff
    80003d62:	4f2080e7          	jalr	1266(ra) # 80003250 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d66:	013d09bb          	addw	s3,s10,s3
    80003d6a:	012d093b          	addw	s2,s10,s2
    80003d6e:	9a6e                	add	s4,s4,s11
    80003d70:	0569f663          	bgeu	s3,s6,80003dbc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d74:	00a9559b          	srliw	a1,s2,0xa
    80003d78:	8556                	mv	a0,s5
    80003d7a:	fffff097          	auipc	ra,0xfffff
    80003d7e:	7a0080e7          	jalr	1952(ra) # 8000351a <bmap>
    80003d82:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d86:	c99d                	beqz	a1,80003dbc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d88:	000aa503          	lw	a0,0(s5)
    80003d8c:	fffff097          	auipc	ra,0xfffff
    80003d90:	394080e7          	jalr	916(ra) # 80003120 <bread>
    80003d94:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d96:	3ff97713          	andi	a4,s2,1023
    80003d9a:	40ec87bb          	subw	a5,s9,a4
    80003d9e:	413b06bb          	subw	a3,s6,s3
    80003da2:	8d3e                	mv	s10,a5
    80003da4:	2781                	sext.w	a5,a5
    80003da6:	0006861b          	sext.w	a2,a3
    80003daa:	f8f674e3          	bgeu	a2,a5,80003d32 <writei+0x4c>
    80003dae:	8d36                	mv	s10,a3
    80003db0:	b749                	j	80003d32 <writei+0x4c>
      brelse(bp);
    80003db2:	8526                	mv	a0,s1
    80003db4:	fffff097          	auipc	ra,0xfffff
    80003db8:	49c080e7          	jalr	1180(ra) # 80003250 <brelse>
  }

  if(off > ip->size)
    80003dbc:	04caa783          	lw	a5,76(s5)
    80003dc0:	0127f463          	bgeu	a5,s2,80003dc8 <writei+0xe2>
    ip->size = off;
    80003dc4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dc8:	8556                	mv	a0,s5
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	aa6080e7          	jalr	-1370(ra) # 80003870 <iupdate>

  return tot;
    80003dd2:	0009851b          	sext.w	a0,s3
}
    80003dd6:	70a6                	ld	ra,104(sp)
    80003dd8:	7406                	ld	s0,96(sp)
    80003dda:	64e6                	ld	s1,88(sp)
    80003ddc:	6946                	ld	s2,80(sp)
    80003dde:	69a6                	ld	s3,72(sp)
    80003de0:	6a06                	ld	s4,64(sp)
    80003de2:	7ae2                	ld	s5,56(sp)
    80003de4:	7b42                	ld	s6,48(sp)
    80003de6:	7ba2                	ld	s7,40(sp)
    80003de8:	7c02                	ld	s8,32(sp)
    80003dea:	6ce2                	ld	s9,24(sp)
    80003dec:	6d42                	ld	s10,16(sp)
    80003dee:	6da2                	ld	s11,8(sp)
    80003df0:	6165                	addi	sp,sp,112
    80003df2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df4:	89da                	mv	s3,s6
    80003df6:	bfc9                	j	80003dc8 <writei+0xe2>
    return -1;
    80003df8:	557d                	li	a0,-1
}
    80003dfa:	8082                	ret
    return -1;
    80003dfc:	557d                	li	a0,-1
    80003dfe:	bfe1                	j	80003dd6 <writei+0xf0>
    return -1;
    80003e00:	557d                	li	a0,-1
    80003e02:	bfd1                	j	80003dd6 <writei+0xf0>

0000000080003e04 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e04:	1141                	addi	sp,sp,-16
    80003e06:	e406                	sd	ra,8(sp)
    80003e08:	e022                	sd	s0,0(sp)
    80003e0a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e0c:	4639                	li	a2,14
    80003e0e:	ffffd097          	auipc	ra,0xffffd
    80003e12:	fb0080e7          	jalr	-80(ra) # 80000dbe <strncmp>
}
    80003e16:	60a2                	ld	ra,8(sp)
    80003e18:	6402                	ld	s0,0(sp)
    80003e1a:	0141                	addi	sp,sp,16
    80003e1c:	8082                	ret

0000000080003e1e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e1e:	7139                	addi	sp,sp,-64
    80003e20:	fc06                	sd	ra,56(sp)
    80003e22:	f822                	sd	s0,48(sp)
    80003e24:	f426                	sd	s1,40(sp)
    80003e26:	f04a                	sd	s2,32(sp)
    80003e28:	ec4e                	sd	s3,24(sp)
    80003e2a:	e852                	sd	s4,16(sp)
    80003e2c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e2e:	04451703          	lh	a4,68(a0)
    80003e32:	4785                	li	a5,1
    80003e34:	00f71a63          	bne	a4,a5,80003e48 <dirlookup+0x2a>
    80003e38:	892a                	mv	s2,a0
    80003e3a:	89ae                	mv	s3,a1
    80003e3c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3e:	457c                	lw	a5,76(a0)
    80003e40:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e42:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e44:	e79d                	bnez	a5,80003e72 <dirlookup+0x54>
    80003e46:	a8a5                	j	80003ebe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e48:	00005517          	auipc	a0,0x5
    80003e4c:	95050513          	addi	a0,a0,-1712 # 80008798 <syscalls+0x1b8>
    80003e50:	ffffc097          	auipc	ra,0xffffc
    80003e54:	6f4080e7          	jalr	1780(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003e58:	00005517          	auipc	a0,0x5
    80003e5c:	95850513          	addi	a0,a0,-1704 # 800087b0 <syscalls+0x1d0>
    80003e60:	ffffc097          	auipc	ra,0xffffc
    80003e64:	6e4080e7          	jalr	1764(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e68:	24c1                	addiw	s1,s1,16
    80003e6a:	04c92783          	lw	a5,76(s2)
    80003e6e:	04f4f763          	bgeu	s1,a5,80003ebc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e72:	4741                	li	a4,16
    80003e74:	86a6                	mv	a3,s1
    80003e76:	fc040613          	addi	a2,s0,-64
    80003e7a:	4581                	li	a1,0
    80003e7c:	854a                	mv	a0,s2
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	d70080e7          	jalr	-656(ra) # 80003bee <readi>
    80003e86:	47c1                	li	a5,16
    80003e88:	fcf518e3          	bne	a0,a5,80003e58 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e8c:	fc045783          	lhu	a5,-64(s0)
    80003e90:	dfe1                	beqz	a5,80003e68 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e92:	fc240593          	addi	a1,s0,-62
    80003e96:	854e                	mv	a0,s3
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	f6c080e7          	jalr	-148(ra) # 80003e04 <namecmp>
    80003ea0:	f561                	bnez	a0,80003e68 <dirlookup+0x4a>
      if(poff)
    80003ea2:	000a0463          	beqz	s4,80003eaa <dirlookup+0x8c>
        *poff = off;
    80003ea6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003eaa:	fc045583          	lhu	a1,-64(s0)
    80003eae:	00092503          	lw	a0,0(s2)
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	750080e7          	jalr	1872(ra) # 80003602 <iget>
    80003eba:	a011                	j	80003ebe <dirlookup+0xa0>
  return 0;
    80003ebc:	4501                	li	a0,0
}
    80003ebe:	70e2                	ld	ra,56(sp)
    80003ec0:	7442                	ld	s0,48(sp)
    80003ec2:	74a2                	ld	s1,40(sp)
    80003ec4:	7902                	ld	s2,32(sp)
    80003ec6:	69e2                	ld	s3,24(sp)
    80003ec8:	6a42                	ld	s4,16(sp)
    80003eca:	6121                	addi	sp,sp,64
    80003ecc:	8082                	ret

0000000080003ece <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ece:	711d                	addi	sp,sp,-96
    80003ed0:	ec86                	sd	ra,88(sp)
    80003ed2:	e8a2                	sd	s0,80(sp)
    80003ed4:	e4a6                	sd	s1,72(sp)
    80003ed6:	e0ca                	sd	s2,64(sp)
    80003ed8:	fc4e                	sd	s3,56(sp)
    80003eda:	f852                	sd	s4,48(sp)
    80003edc:	f456                	sd	s5,40(sp)
    80003ede:	f05a                	sd	s6,32(sp)
    80003ee0:	ec5e                	sd	s7,24(sp)
    80003ee2:	e862                	sd	s8,16(sp)
    80003ee4:	e466                	sd	s9,8(sp)
    80003ee6:	1080                	addi	s0,sp,96
    80003ee8:	84aa                	mv	s1,a0
    80003eea:	8b2e                	mv	s6,a1
    80003eec:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eee:	00054703          	lbu	a4,0(a0)
    80003ef2:	02f00793          	li	a5,47
    80003ef6:	02f70363          	beq	a4,a5,80003f1c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003efa:	ffffe097          	auipc	ra,0xffffe
    80003efe:	acc080e7          	jalr	-1332(ra) # 800019c6 <myproc>
    80003f02:	15053503          	ld	a0,336(a0)
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	9f6080e7          	jalr	-1546(ra) # 800038fc <idup>
    80003f0e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f10:	02f00913          	li	s2,47
  len = path - s;
    80003f14:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f16:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f18:	4c05                	li	s8,1
    80003f1a:	a865                	j	80003fd2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f1c:	4585                	li	a1,1
    80003f1e:	4505                	li	a0,1
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	6e2080e7          	jalr	1762(ra) # 80003602 <iget>
    80003f28:	89aa                	mv	s3,a0
    80003f2a:	b7dd                	j	80003f10 <namex+0x42>
      iunlockput(ip);
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	c6e080e7          	jalr	-914(ra) # 80003b9c <iunlockput>
      return 0;
    80003f36:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f38:	854e                	mv	a0,s3
    80003f3a:	60e6                	ld	ra,88(sp)
    80003f3c:	6446                	ld	s0,80(sp)
    80003f3e:	64a6                	ld	s1,72(sp)
    80003f40:	6906                	ld	s2,64(sp)
    80003f42:	79e2                	ld	s3,56(sp)
    80003f44:	7a42                	ld	s4,48(sp)
    80003f46:	7aa2                	ld	s5,40(sp)
    80003f48:	7b02                	ld	s6,32(sp)
    80003f4a:	6be2                	ld	s7,24(sp)
    80003f4c:	6c42                	ld	s8,16(sp)
    80003f4e:	6ca2                	ld	s9,8(sp)
    80003f50:	6125                	addi	sp,sp,96
    80003f52:	8082                	ret
      iunlock(ip);
    80003f54:	854e                	mv	a0,s3
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	aa6080e7          	jalr	-1370(ra) # 800039fc <iunlock>
      return ip;
    80003f5e:	bfe9                	j	80003f38 <namex+0x6a>
      iunlockput(ip);
    80003f60:	854e                	mv	a0,s3
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	c3a080e7          	jalr	-966(ra) # 80003b9c <iunlockput>
      return 0;
    80003f6a:	89d2                	mv	s3,s4
    80003f6c:	b7f1                	j	80003f38 <namex+0x6a>
  len = path - s;
    80003f6e:	40b48633          	sub	a2,s1,a1
    80003f72:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f76:	094cd463          	bge	s9,s4,80003ffe <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f7a:	4639                	li	a2,14
    80003f7c:	8556                	mv	a0,s5
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	dc8080e7          	jalr	-568(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003f86:	0004c783          	lbu	a5,0(s1)
    80003f8a:	01279763          	bne	a5,s2,80003f98 <namex+0xca>
    path++;
    80003f8e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f90:	0004c783          	lbu	a5,0(s1)
    80003f94:	ff278de3          	beq	a5,s2,80003f8e <namex+0xc0>
    ilock(ip);
    80003f98:	854e                	mv	a0,s3
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	9a0080e7          	jalr	-1632(ra) # 8000393a <ilock>
    if(ip->type != T_DIR){
    80003fa2:	04499783          	lh	a5,68(s3)
    80003fa6:	f98793e3          	bne	a5,s8,80003f2c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003faa:	000b0563          	beqz	s6,80003fb4 <namex+0xe6>
    80003fae:	0004c783          	lbu	a5,0(s1)
    80003fb2:	d3cd                	beqz	a5,80003f54 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fb4:	865e                	mv	a2,s7
    80003fb6:	85d6                	mv	a1,s5
    80003fb8:	854e                	mv	a0,s3
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	e64080e7          	jalr	-412(ra) # 80003e1e <dirlookup>
    80003fc2:	8a2a                	mv	s4,a0
    80003fc4:	dd51                	beqz	a0,80003f60 <namex+0x92>
    iunlockput(ip);
    80003fc6:	854e                	mv	a0,s3
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	bd4080e7          	jalr	-1068(ra) # 80003b9c <iunlockput>
    ip = next;
    80003fd0:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fd2:	0004c783          	lbu	a5,0(s1)
    80003fd6:	05279763          	bne	a5,s2,80004024 <namex+0x156>
    path++;
    80003fda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fdc:	0004c783          	lbu	a5,0(s1)
    80003fe0:	ff278de3          	beq	a5,s2,80003fda <namex+0x10c>
  if(*path == 0)
    80003fe4:	c79d                	beqz	a5,80004012 <namex+0x144>
    path++;
    80003fe6:	85a6                	mv	a1,s1
  len = path - s;
    80003fe8:	8a5e                	mv	s4,s7
    80003fea:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fec:	01278963          	beq	a5,s2,80003ffe <namex+0x130>
    80003ff0:	dfbd                	beqz	a5,80003f6e <namex+0xa0>
    path++;
    80003ff2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ff4:	0004c783          	lbu	a5,0(s1)
    80003ff8:	ff279ce3          	bne	a5,s2,80003ff0 <namex+0x122>
    80003ffc:	bf8d                	j	80003f6e <namex+0xa0>
    memmove(name, s, len);
    80003ffe:	2601                	sext.w	a2,a2
    80004000:	8556                	mv	a0,s5
    80004002:	ffffd097          	auipc	ra,0xffffd
    80004006:	d44080e7          	jalr	-700(ra) # 80000d46 <memmove>
    name[len] = 0;
    8000400a:	9a56                	add	s4,s4,s5
    8000400c:	000a0023          	sb	zero,0(s4)
    80004010:	bf9d                	j	80003f86 <namex+0xb8>
  if(nameiparent){
    80004012:	f20b03e3          	beqz	s6,80003f38 <namex+0x6a>
    iput(ip);
    80004016:	854e                	mv	a0,s3
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	adc080e7          	jalr	-1316(ra) # 80003af4 <iput>
    return 0;
    80004020:	4981                	li	s3,0
    80004022:	bf19                	j	80003f38 <namex+0x6a>
  if(*path == 0)
    80004024:	d7fd                	beqz	a5,80004012 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004026:	0004c783          	lbu	a5,0(s1)
    8000402a:	85a6                	mv	a1,s1
    8000402c:	b7d1                	j	80003ff0 <namex+0x122>

000000008000402e <dirlink>:
{
    8000402e:	7139                	addi	sp,sp,-64
    80004030:	fc06                	sd	ra,56(sp)
    80004032:	f822                	sd	s0,48(sp)
    80004034:	f426                	sd	s1,40(sp)
    80004036:	f04a                	sd	s2,32(sp)
    80004038:	ec4e                	sd	s3,24(sp)
    8000403a:	e852                	sd	s4,16(sp)
    8000403c:	0080                	addi	s0,sp,64
    8000403e:	892a                	mv	s2,a0
    80004040:	8a2e                	mv	s4,a1
    80004042:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004044:	4601                	li	a2,0
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	dd8080e7          	jalr	-552(ra) # 80003e1e <dirlookup>
    8000404e:	e93d                	bnez	a0,800040c4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004050:	04c92483          	lw	s1,76(s2)
    80004054:	c49d                	beqz	s1,80004082 <dirlink+0x54>
    80004056:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004058:	4741                	li	a4,16
    8000405a:	86a6                	mv	a3,s1
    8000405c:	fc040613          	addi	a2,s0,-64
    80004060:	4581                	li	a1,0
    80004062:	854a                	mv	a0,s2
    80004064:	00000097          	auipc	ra,0x0
    80004068:	b8a080e7          	jalr	-1142(ra) # 80003bee <readi>
    8000406c:	47c1                	li	a5,16
    8000406e:	06f51163          	bne	a0,a5,800040d0 <dirlink+0xa2>
    if(de.inum == 0)
    80004072:	fc045783          	lhu	a5,-64(s0)
    80004076:	c791                	beqz	a5,80004082 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004078:	24c1                	addiw	s1,s1,16
    8000407a:	04c92783          	lw	a5,76(s2)
    8000407e:	fcf4ede3          	bltu	s1,a5,80004058 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004082:	4639                	li	a2,14
    80004084:	85d2                	mv	a1,s4
    80004086:	fc240513          	addi	a0,s0,-62
    8000408a:	ffffd097          	auipc	ra,0xffffd
    8000408e:	d70080e7          	jalr	-656(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80004092:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004096:	4741                	li	a4,16
    80004098:	86a6                	mv	a3,s1
    8000409a:	fc040613          	addi	a2,s0,-64
    8000409e:	4581                	li	a1,0
    800040a0:	854a                	mv	a0,s2
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	c44080e7          	jalr	-956(ra) # 80003ce6 <writei>
    800040aa:	1541                	addi	a0,a0,-16
    800040ac:	00a03533          	snez	a0,a0
    800040b0:	40a00533          	neg	a0,a0
}
    800040b4:	70e2                	ld	ra,56(sp)
    800040b6:	7442                	ld	s0,48(sp)
    800040b8:	74a2                	ld	s1,40(sp)
    800040ba:	7902                	ld	s2,32(sp)
    800040bc:	69e2                	ld	s3,24(sp)
    800040be:	6a42                	ld	s4,16(sp)
    800040c0:	6121                	addi	sp,sp,64
    800040c2:	8082                	ret
    iput(ip);
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	a30080e7          	jalr	-1488(ra) # 80003af4 <iput>
    return -1;
    800040cc:	557d                	li	a0,-1
    800040ce:	b7dd                	j	800040b4 <dirlink+0x86>
      panic("dirlink read");
    800040d0:	00004517          	auipc	a0,0x4
    800040d4:	6f050513          	addi	a0,a0,1776 # 800087c0 <syscalls+0x1e0>
    800040d8:	ffffc097          	auipc	ra,0xffffc
    800040dc:	46c080e7          	jalr	1132(ra) # 80000544 <panic>

00000000800040e0 <namei>:

struct inode*
namei(char *path)
{
    800040e0:	1101                	addi	sp,sp,-32
    800040e2:	ec06                	sd	ra,24(sp)
    800040e4:	e822                	sd	s0,16(sp)
    800040e6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040e8:	fe040613          	addi	a2,s0,-32
    800040ec:	4581                	li	a1,0
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	de0080e7          	jalr	-544(ra) # 80003ece <namex>
}
    800040f6:	60e2                	ld	ra,24(sp)
    800040f8:	6442                	ld	s0,16(sp)
    800040fa:	6105                	addi	sp,sp,32
    800040fc:	8082                	ret

00000000800040fe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040fe:	1141                	addi	sp,sp,-16
    80004100:	e406                	sd	ra,8(sp)
    80004102:	e022                	sd	s0,0(sp)
    80004104:	0800                	addi	s0,sp,16
    80004106:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004108:	4585                	li	a1,1
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	dc4080e7          	jalr	-572(ra) # 80003ece <namex>
}
    80004112:	60a2                	ld	ra,8(sp)
    80004114:	6402                	ld	s0,0(sp)
    80004116:	0141                	addi	sp,sp,16
    80004118:	8082                	ret

000000008000411a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000411a:	1101                	addi	sp,sp,-32
    8000411c:	ec06                	sd	ra,24(sp)
    8000411e:	e822                	sd	s0,16(sp)
    80004120:	e426                	sd	s1,8(sp)
    80004122:	e04a                	sd	s2,0(sp)
    80004124:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004126:	0001d917          	auipc	s2,0x1d
    8000412a:	48a90913          	addi	s2,s2,1162 # 800215b0 <log>
    8000412e:	01892583          	lw	a1,24(s2)
    80004132:	02892503          	lw	a0,40(s2)
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	fea080e7          	jalr	-22(ra) # 80003120 <bread>
    8000413e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004140:	02c92683          	lw	a3,44(s2)
    80004144:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004146:	02d05763          	blez	a3,80004174 <write_head+0x5a>
    8000414a:	0001d797          	auipc	a5,0x1d
    8000414e:	49678793          	addi	a5,a5,1174 # 800215e0 <log+0x30>
    80004152:	05c50713          	addi	a4,a0,92
    80004156:	36fd                	addiw	a3,a3,-1
    80004158:	1682                	slli	a3,a3,0x20
    8000415a:	9281                	srli	a3,a3,0x20
    8000415c:	068a                	slli	a3,a3,0x2
    8000415e:	0001d617          	auipc	a2,0x1d
    80004162:	48660613          	addi	a2,a2,1158 # 800215e4 <log+0x34>
    80004166:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004168:	4390                	lw	a2,0(a5)
    8000416a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000416c:	0791                	addi	a5,a5,4
    8000416e:	0711                	addi	a4,a4,4
    80004170:	fed79ce3          	bne	a5,a3,80004168 <write_head+0x4e>
  }
  bwrite(buf);
    80004174:	8526                	mv	a0,s1
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	09c080e7          	jalr	156(ra) # 80003212 <bwrite>
  brelse(buf);
    8000417e:	8526                	mv	a0,s1
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	0d0080e7          	jalr	208(ra) # 80003250 <brelse>
}
    80004188:	60e2                	ld	ra,24(sp)
    8000418a:	6442                	ld	s0,16(sp)
    8000418c:	64a2                	ld	s1,8(sp)
    8000418e:	6902                	ld	s2,0(sp)
    80004190:	6105                	addi	sp,sp,32
    80004192:	8082                	ret

0000000080004194 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004194:	0001d797          	auipc	a5,0x1d
    80004198:	4487a783          	lw	a5,1096(a5) # 800215dc <log+0x2c>
    8000419c:	0af05d63          	blez	a5,80004256 <install_trans+0xc2>
{
    800041a0:	7139                	addi	sp,sp,-64
    800041a2:	fc06                	sd	ra,56(sp)
    800041a4:	f822                	sd	s0,48(sp)
    800041a6:	f426                	sd	s1,40(sp)
    800041a8:	f04a                	sd	s2,32(sp)
    800041aa:	ec4e                	sd	s3,24(sp)
    800041ac:	e852                	sd	s4,16(sp)
    800041ae:	e456                	sd	s5,8(sp)
    800041b0:	e05a                	sd	s6,0(sp)
    800041b2:	0080                	addi	s0,sp,64
    800041b4:	8b2a                	mv	s6,a0
    800041b6:	0001da97          	auipc	s5,0x1d
    800041ba:	42aa8a93          	addi	s5,s5,1066 # 800215e0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041be:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041c0:	0001d997          	auipc	s3,0x1d
    800041c4:	3f098993          	addi	s3,s3,1008 # 800215b0 <log>
    800041c8:	a035                	j	800041f4 <install_trans+0x60>
      bunpin(dbuf);
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	15e080e7          	jalr	350(ra) # 8000332a <bunpin>
    brelse(lbuf);
    800041d4:	854a                	mv	a0,s2
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	07a080e7          	jalr	122(ra) # 80003250 <brelse>
    brelse(dbuf);
    800041de:	8526                	mv	a0,s1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	070080e7          	jalr	112(ra) # 80003250 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e8:	2a05                	addiw	s4,s4,1
    800041ea:	0a91                	addi	s5,s5,4
    800041ec:	02c9a783          	lw	a5,44(s3)
    800041f0:	04fa5963          	bge	s4,a5,80004242 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f4:	0189a583          	lw	a1,24(s3)
    800041f8:	014585bb          	addw	a1,a1,s4
    800041fc:	2585                	addiw	a1,a1,1
    800041fe:	0289a503          	lw	a0,40(s3)
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	f1e080e7          	jalr	-226(ra) # 80003120 <bread>
    8000420a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000420c:	000aa583          	lw	a1,0(s5)
    80004210:	0289a503          	lw	a0,40(s3)
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	f0c080e7          	jalr	-244(ra) # 80003120 <bread>
    8000421c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000421e:	40000613          	li	a2,1024
    80004222:	05890593          	addi	a1,s2,88
    80004226:	05850513          	addi	a0,a0,88
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	b1c080e7          	jalr	-1252(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004232:	8526                	mv	a0,s1
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	fde080e7          	jalr	-34(ra) # 80003212 <bwrite>
    if(recovering == 0)
    8000423c:	f80b1ce3          	bnez	s6,800041d4 <install_trans+0x40>
    80004240:	b769                	j	800041ca <install_trans+0x36>
}
    80004242:	70e2                	ld	ra,56(sp)
    80004244:	7442                	ld	s0,48(sp)
    80004246:	74a2                	ld	s1,40(sp)
    80004248:	7902                	ld	s2,32(sp)
    8000424a:	69e2                	ld	s3,24(sp)
    8000424c:	6a42                	ld	s4,16(sp)
    8000424e:	6aa2                	ld	s5,8(sp)
    80004250:	6b02                	ld	s6,0(sp)
    80004252:	6121                	addi	sp,sp,64
    80004254:	8082                	ret
    80004256:	8082                	ret

0000000080004258 <initlog>:
{
    80004258:	7179                	addi	sp,sp,-48
    8000425a:	f406                	sd	ra,40(sp)
    8000425c:	f022                	sd	s0,32(sp)
    8000425e:	ec26                	sd	s1,24(sp)
    80004260:	e84a                	sd	s2,16(sp)
    80004262:	e44e                	sd	s3,8(sp)
    80004264:	1800                	addi	s0,sp,48
    80004266:	892a                	mv	s2,a0
    80004268:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000426a:	0001d497          	auipc	s1,0x1d
    8000426e:	34648493          	addi	s1,s1,838 # 800215b0 <log>
    80004272:	00004597          	auipc	a1,0x4
    80004276:	55e58593          	addi	a1,a1,1374 # 800087d0 <syscalls+0x1f0>
    8000427a:	8526                	mv	a0,s1
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	8de080e7          	jalr	-1826(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004284:	0149a583          	lw	a1,20(s3)
    80004288:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000428a:	0109a783          	lw	a5,16(s3)
    8000428e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004290:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004294:	854a                	mv	a0,s2
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	e8a080e7          	jalr	-374(ra) # 80003120 <bread>
  log.lh.n = lh->n;
    8000429e:	4d3c                	lw	a5,88(a0)
    800042a0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042a2:	02f05563          	blez	a5,800042cc <initlog+0x74>
    800042a6:	05c50713          	addi	a4,a0,92
    800042aa:	0001d697          	auipc	a3,0x1d
    800042ae:	33668693          	addi	a3,a3,822 # 800215e0 <log+0x30>
    800042b2:	37fd                	addiw	a5,a5,-1
    800042b4:	1782                	slli	a5,a5,0x20
    800042b6:	9381                	srli	a5,a5,0x20
    800042b8:	078a                	slli	a5,a5,0x2
    800042ba:	06050613          	addi	a2,a0,96
    800042be:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042c0:	4310                	lw	a2,0(a4)
    800042c2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042c4:	0711                	addi	a4,a4,4
    800042c6:	0691                	addi	a3,a3,4
    800042c8:	fef71ce3          	bne	a4,a5,800042c0 <initlog+0x68>
  brelse(buf);
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	f84080e7          	jalr	-124(ra) # 80003250 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042d4:	4505                	li	a0,1
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	ebe080e7          	jalr	-322(ra) # 80004194 <install_trans>
  log.lh.n = 0;
    800042de:	0001d797          	auipc	a5,0x1d
    800042e2:	2e07af23          	sw	zero,766(a5) # 800215dc <log+0x2c>
  write_head(); // clear the log
    800042e6:	00000097          	auipc	ra,0x0
    800042ea:	e34080e7          	jalr	-460(ra) # 8000411a <write_head>
}
    800042ee:	70a2                	ld	ra,40(sp)
    800042f0:	7402                	ld	s0,32(sp)
    800042f2:	64e2                	ld	s1,24(sp)
    800042f4:	6942                	ld	s2,16(sp)
    800042f6:	69a2                	ld	s3,8(sp)
    800042f8:	6145                	addi	sp,sp,48
    800042fa:	8082                	ret

00000000800042fc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042fc:	1101                	addi	sp,sp,-32
    800042fe:	ec06                	sd	ra,24(sp)
    80004300:	e822                	sd	s0,16(sp)
    80004302:	e426                	sd	s1,8(sp)
    80004304:	e04a                	sd	s2,0(sp)
    80004306:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004308:	0001d517          	auipc	a0,0x1d
    8000430c:	2a850513          	addi	a0,a0,680 # 800215b0 <log>
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	8da080e7          	jalr	-1830(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004318:	0001d497          	auipc	s1,0x1d
    8000431c:	29848493          	addi	s1,s1,664 # 800215b0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004320:	4979                	li	s2,30
    80004322:	a039                	j	80004330 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004324:	85a6                	mv	a1,s1
    80004326:	8526                	mv	a0,s1
    80004328:	ffffe097          	auipc	ra,0xffffe
    8000432c:	d7e080e7          	jalr	-642(ra) # 800020a6 <sleep>
    if(log.committing){
    80004330:	50dc                	lw	a5,36(s1)
    80004332:	fbed                	bnez	a5,80004324 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004334:	509c                	lw	a5,32(s1)
    80004336:	0017871b          	addiw	a4,a5,1
    8000433a:	0007069b          	sext.w	a3,a4
    8000433e:	0027179b          	slliw	a5,a4,0x2
    80004342:	9fb9                	addw	a5,a5,a4
    80004344:	0017979b          	slliw	a5,a5,0x1
    80004348:	54d8                	lw	a4,44(s1)
    8000434a:	9fb9                	addw	a5,a5,a4
    8000434c:	00f95963          	bge	s2,a5,8000435e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004350:	85a6                	mv	a1,s1
    80004352:	8526                	mv	a0,s1
    80004354:	ffffe097          	auipc	ra,0xffffe
    80004358:	d52080e7          	jalr	-686(ra) # 800020a6 <sleep>
    8000435c:	bfd1                	j	80004330 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000435e:	0001d517          	auipc	a0,0x1d
    80004362:	25250513          	addi	a0,a0,594 # 800215b0 <log>
    80004366:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	936080e7          	jalr	-1738(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004370:	60e2                	ld	ra,24(sp)
    80004372:	6442                	ld	s0,16(sp)
    80004374:	64a2                	ld	s1,8(sp)
    80004376:	6902                	ld	s2,0(sp)
    80004378:	6105                	addi	sp,sp,32
    8000437a:	8082                	ret

000000008000437c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000437c:	7139                	addi	sp,sp,-64
    8000437e:	fc06                	sd	ra,56(sp)
    80004380:	f822                	sd	s0,48(sp)
    80004382:	f426                	sd	s1,40(sp)
    80004384:	f04a                	sd	s2,32(sp)
    80004386:	ec4e                	sd	s3,24(sp)
    80004388:	e852                	sd	s4,16(sp)
    8000438a:	e456                	sd	s5,8(sp)
    8000438c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000438e:	0001d497          	auipc	s1,0x1d
    80004392:	22248493          	addi	s1,s1,546 # 800215b0 <log>
    80004396:	8526                	mv	a0,s1
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	852080e7          	jalr	-1966(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800043a0:	509c                	lw	a5,32(s1)
    800043a2:	37fd                	addiw	a5,a5,-1
    800043a4:	0007891b          	sext.w	s2,a5
    800043a8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043aa:	50dc                	lw	a5,36(s1)
    800043ac:	efb9                	bnez	a5,8000440a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043ae:	06091663          	bnez	s2,8000441a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043b2:	0001d497          	auipc	s1,0x1d
    800043b6:	1fe48493          	addi	s1,s1,510 # 800215b0 <log>
    800043ba:	4785                	li	a5,1
    800043bc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043be:	8526                	mv	a0,s1
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	8de080e7          	jalr	-1826(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043c8:	54dc                	lw	a5,44(s1)
    800043ca:	06f04763          	bgtz	a5,80004438 <end_op+0xbc>
    acquire(&log.lock);
    800043ce:	0001d497          	auipc	s1,0x1d
    800043d2:	1e248493          	addi	s1,s1,482 # 800215b0 <log>
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	812080e7          	jalr	-2030(ra) # 80000bea <acquire>
    log.committing = 0;
    800043e0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043e4:	8526                	mv	a0,s1
    800043e6:	ffffe097          	auipc	ra,0xffffe
    800043ea:	d24080e7          	jalr	-732(ra) # 8000210a <wakeup>
    release(&log.lock);
    800043ee:	8526                	mv	a0,s1
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	8ae080e7          	jalr	-1874(ra) # 80000c9e <release>
}
    800043f8:	70e2                	ld	ra,56(sp)
    800043fa:	7442                	ld	s0,48(sp)
    800043fc:	74a2                	ld	s1,40(sp)
    800043fe:	7902                	ld	s2,32(sp)
    80004400:	69e2                	ld	s3,24(sp)
    80004402:	6a42                	ld	s4,16(sp)
    80004404:	6aa2                	ld	s5,8(sp)
    80004406:	6121                	addi	sp,sp,64
    80004408:	8082                	ret
    panic("log.committing");
    8000440a:	00004517          	auipc	a0,0x4
    8000440e:	3ce50513          	addi	a0,a0,974 # 800087d8 <syscalls+0x1f8>
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	132080e7          	jalr	306(ra) # 80000544 <panic>
    wakeup(&log);
    8000441a:	0001d497          	auipc	s1,0x1d
    8000441e:	19648493          	addi	s1,s1,406 # 800215b0 <log>
    80004422:	8526                	mv	a0,s1
    80004424:	ffffe097          	auipc	ra,0xffffe
    80004428:	ce6080e7          	jalr	-794(ra) # 8000210a <wakeup>
  release(&log.lock);
    8000442c:	8526                	mv	a0,s1
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	870080e7          	jalr	-1936(ra) # 80000c9e <release>
  if(do_commit){
    80004436:	b7c9                	j	800043f8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004438:	0001da97          	auipc	s5,0x1d
    8000443c:	1a8a8a93          	addi	s5,s5,424 # 800215e0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004440:	0001da17          	auipc	s4,0x1d
    80004444:	170a0a13          	addi	s4,s4,368 # 800215b0 <log>
    80004448:	018a2583          	lw	a1,24(s4)
    8000444c:	012585bb          	addw	a1,a1,s2
    80004450:	2585                	addiw	a1,a1,1
    80004452:	028a2503          	lw	a0,40(s4)
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	cca080e7          	jalr	-822(ra) # 80003120 <bread>
    8000445e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004460:	000aa583          	lw	a1,0(s5)
    80004464:	028a2503          	lw	a0,40(s4)
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	cb8080e7          	jalr	-840(ra) # 80003120 <bread>
    80004470:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004472:	40000613          	li	a2,1024
    80004476:	05850593          	addi	a1,a0,88
    8000447a:	05848513          	addi	a0,s1,88
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	8c8080e7          	jalr	-1848(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004486:	8526                	mv	a0,s1
    80004488:	fffff097          	auipc	ra,0xfffff
    8000448c:	d8a080e7          	jalr	-630(ra) # 80003212 <bwrite>
    brelse(from);
    80004490:	854e                	mv	a0,s3
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	dbe080e7          	jalr	-578(ra) # 80003250 <brelse>
    brelse(to);
    8000449a:	8526                	mv	a0,s1
    8000449c:	fffff097          	auipc	ra,0xfffff
    800044a0:	db4080e7          	jalr	-588(ra) # 80003250 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a4:	2905                	addiw	s2,s2,1
    800044a6:	0a91                	addi	s5,s5,4
    800044a8:	02ca2783          	lw	a5,44(s4)
    800044ac:	f8f94ee3          	blt	s2,a5,80004448 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	c6a080e7          	jalr	-918(ra) # 8000411a <write_head>
    install_trans(0); // Now install writes to home locations
    800044b8:	4501                	li	a0,0
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	cda080e7          	jalr	-806(ra) # 80004194 <install_trans>
    log.lh.n = 0;
    800044c2:	0001d797          	auipc	a5,0x1d
    800044c6:	1007ad23          	sw	zero,282(a5) # 800215dc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	c50080e7          	jalr	-944(ra) # 8000411a <write_head>
    800044d2:	bdf5                	j	800043ce <end_op+0x52>

00000000800044d4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044d4:	1101                	addi	sp,sp,-32
    800044d6:	ec06                	sd	ra,24(sp)
    800044d8:	e822                	sd	s0,16(sp)
    800044da:	e426                	sd	s1,8(sp)
    800044dc:	e04a                	sd	s2,0(sp)
    800044de:	1000                	addi	s0,sp,32
    800044e0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044e2:	0001d917          	auipc	s2,0x1d
    800044e6:	0ce90913          	addi	s2,s2,206 # 800215b0 <log>
    800044ea:	854a                	mv	a0,s2
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	6fe080e7          	jalr	1790(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044f4:	02c92603          	lw	a2,44(s2)
    800044f8:	47f5                	li	a5,29
    800044fa:	06c7c563          	blt	a5,a2,80004564 <log_write+0x90>
    800044fe:	0001d797          	auipc	a5,0x1d
    80004502:	0ce7a783          	lw	a5,206(a5) # 800215cc <log+0x1c>
    80004506:	37fd                	addiw	a5,a5,-1
    80004508:	04f65e63          	bge	a2,a5,80004564 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000450c:	0001d797          	auipc	a5,0x1d
    80004510:	0c47a783          	lw	a5,196(a5) # 800215d0 <log+0x20>
    80004514:	06f05063          	blez	a5,80004574 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004518:	4781                	li	a5,0
    8000451a:	06c05563          	blez	a2,80004584 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000451e:	44cc                	lw	a1,12(s1)
    80004520:	0001d717          	auipc	a4,0x1d
    80004524:	0c070713          	addi	a4,a4,192 # 800215e0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004528:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000452a:	4314                	lw	a3,0(a4)
    8000452c:	04b68c63          	beq	a3,a1,80004584 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004530:	2785                	addiw	a5,a5,1
    80004532:	0711                	addi	a4,a4,4
    80004534:	fef61be3          	bne	a2,a5,8000452a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004538:	0621                	addi	a2,a2,8
    8000453a:	060a                	slli	a2,a2,0x2
    8000453c:	0001d797          	auipc	a5,0x1d
    80004540:	07478793          	addi	a5,a5,116 # 800215b0 <log>
    80004544:	963e                	add	a2,a2,a5
    80004546:	44dc                	lw	a5,12(s1)
    80004548:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000454a:	8526                	mv	a0,s1
    8000454c:	fffff097          	auipc	ra,0xfffff
    80004550:	da2080e7          	jalr	-606(ra) # 800032ee <bpin>
    log.lh.n++;
    80004554:	0001d717          	auipc	a4,0x1d
    80004558:	05c70713          	addi	a4,a4,92 # 800215b0 <log>
    8000455c:	575c                	lw	a5,44(a4)
    8000455e:	2785                	addiw	a5,a5,1
    80004560:	d75c                	sw	a5,44(a4)
    80004562:	a835                	j	8000459e <log_write+0xca>
    panic("too big a transaction");
    80004564:	00004517          	auipc	a0,0x4
    80004568:	28450513          	addi	a0,a0,644 # 800087e8 <syscalls+0x208>
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	fd8080e7          	jalr	-40(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004574:	00004517          	auipc	a0,0x4
    80004578:	28c50513          	addi	a0,a0,652 # 80008800 <syscalls+0x220>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	fc8080e7          	jalr	-56(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004584:	00878713          	addi	a4,a5,8
    80004588:	00271693          	slli	a3,a4,0x2
    8000458c:	0001d717          	auipc	a4,0x1d
    80004590:	02470713          	addi	a4,a4,36 # 800215b0 <log>
    80004594:	9736                	add	a4,a4,a3
    80004596:	44d4                	lw	a3,12(s1)
    80004598:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000459a:	faf608e3          	beq	a2,a5,8000454a <log_write+0x76>
  }
  release(&log.lock);
    8000459e:	0001d517          	auipc	a0,0x1d
    800045a2:	01250513          	addi	a0,a0,18 # 800215b0 <log>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	6f8080e7          	jalr	1784(ra) # 80000c9e <release>
}
    800045ae:	60e2                	ld	ra,24(sp)
    800045b0:	6442                	ld	s0,16(sp)
    800045b2:	64a2                	ld	s1,8(sp)
    800045b4:	6902                	ld	s2,0(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045ba:	1101                	addi	sp,sp,-32
    800045bc:	ec06                	sd	ra,24(sp)
    800045be:	e822                	sd	s0,16(sp)
    800045c0:	e426                	sd	s1,8(sp)
    800045c2:	e04a                	sd	s2,0(sp)
    800045c4:	1000                	addi	s0,sp,32
    800045c6:	84aa                	mv	s1,a0
    800045c8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045ca:	00004597          	auipc	a1,0x4
    800045ce:	25658593          	addi	a1,a1,598 # 80008820 <syscalls+0x240>
    800045d2:	0521                	addi	a0,a0,8
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	586080e7          	jalr	1414(ra) # 80000b5a <initlock>
  lk->name = name;
    800045dc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045e0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045e4:	0204a423          	sw	zero,40(s1)
}
    800045e8:	60e2                	ld	ra,24(sp)
    800045ea:	6442                	ld	s0,16(sp)
    800045ec:	64a2                	ld	s1,8(sp)
    800045ee:	6902                	ld	s2,0(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret

00000000800045f4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045f4:	1101                	addi	sp,sp,-32
    800045f6:	ec06                	sd	ra,24(sp)
    800045f8:	e822                	sd	s0,16(sp)
    800045fa:	e426                	sd	s1,8(sp)
    800045fc:	e04a                	sd	s2,0(sp)
    800045fe:	1000                	addi	s0,sp,32
    80004600:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004602:	00850913          	addi	s2,a0,8
    80004606:	854a                	mv	a0,s2
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	5e2080e7          	jalr	1506(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004610:	409c                	lw	a5,0(s1)
    80004612:	cb89                	beqz	a5,80004624 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004614:	85ca                	mv	a1,s2
    80004616:	8526                	mv	a0,s1
    80004618:	ffffe097          	auipc	ra,0xffffe
    8000461c:	a8e080e7          	jalr	-1394(ra) # 800020a6 <sleep>
  while (lk->locked) {
    80004620:	409c                	lw	a5,0(s1)
    80004622:	fbed                	bnez	a5,80004614 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004624:	4785                	li	a5,1
    80004626:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004628:	ffffd097          	auipc	ra,0xffffd
    8000462c:	39e080e7          	jalr	926(ra) # 800019c6 <myproc>
    80004630:	591c                	lw	a5,48(a0)
    80004632:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004634:	854a                	mv	a0,s2
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	668080e7          	jalr	1640(ra) # 80000c9e <release>
}
    8000463e:	60e2                	ld	ra,24(sp)
    80004640:	6442                	ld	s0,16(sp)
    80004642:	64a2                	ld	s1,8(sp)
    80004644:	6902                	ld	s2,0(sp)
    80004646:	6105                	addi	sp,sp,32
    80004648:	8082                	ret

000000008000464a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000464a:	1101                	addi	sp,sp,-32
    8000464c:	ec06                	sd	ra,24(sp)
    8000464e:	e822                	sd	s0,16(sp)
    80004650:	e426                	sd	s1,8(sp)
    80004652:	e04a                	sd	s2,0(sp)
    80004654:	1000                	addi	s0,sp,32
    80004656:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004658:	00850913          	addi	s2,a0,8
    8000465c:	854a                	mv	a0,s2
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	58c080e7          	jalr	1420(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004666:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000466a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000466e:	8526                	mv	a0,s1
    80004670:	ffffe097          	auipc	ra,0xffffe
    80004674:	a9a080e7          	jalr	-1382(ra) # 8000210a <wakeup>
  release(&lk->lk);
    80004678:	854a                	mv	a0,s2
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	624080e7          	jalr	1572(ra) # 80000c9e <release>
}
    80004682:	60e2                	ld	ra,24(sp)
    80004684:	6442                	ld	s0,16(sp)
    80004686:	64a2                	ld	s1,8(sp)
    80004688:	6902                	ld	s2,0(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000468e:	7179                	addi	sp,sp,-48
    80004690:	f406                	sd	ra,40(sp)
    80004692:	f022                	sd	s0,32(sp)
    80004694:	ec26                	sd	s1,24(sp)
    80004696:	e84a                	sd	s2,16(sp)
    80004698:	e44e                	sd	s3,8(sp)
    8000469a:	1800                	addi	s0,sp,48
    8000469c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000469e:	00850913          	addi	s2,a0,8
    800046a2:	854a                	mv	a0,s2
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	546080e7          	jalr	1350(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046ac:	409c                	lw	a5,0(s1)
    800046ae:	ef99                	bnez	a5,800046cc <holdingsleep+0x3e>
    800046b0:	4481                	li	s1,0
  release(&lk->lk);
    800046b2:	854a                	mv	a0,s2
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	5ea080e7          	jalr	1514(ra) # 80000c9e <release>
  return r;
}
    800046bc:	8526                	mv	a0,s1
    800046be:	70a2                	ld	ra,40(sp)
    800046c0:	7402                	ld	s0,32(sp)
    800046c2:	64e2                	ld	s1,24(sp)
    800046c4:	6942                	ld	s2,16(sp)
    800046c6:	69a2                	ld	s3,8(sp)
    800046c8:	6145                	addi	sp,sp,48
    800046ca:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046cc:	0284a983          	lw	s3,40(s1)
    800046d0:	ffffd097          	auipc	ra,0xffffd
    800046d4:	2f6080e7          	jalr	758(ra) # 800019c6 <myproc>
    800046d8:	5904                	lw	s1,48(a0)
    800046da:	413484b3          	sub	s1,s1,s3
    800046de:	0014b493          	seqz	s1,s1
    800046e2:	bfc1                	j	800046b2 <holdingsleep+0x24>

00000000800046e4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046e4:	1141                	addi	sp,sp,-16
    800046e6:	e406                	sd	ra,8(sp)
    800046e8:	e022                	sd	s0,0(sp)
    800046ea:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046ec:	00004597          	auipc	a1,0x4
    800046f0:	14458593          	addi	a1,a1,324 # 80008830 <syscalls+0x250>
    800046f4:	0001d517          	auipc	a0,0x1d
    800046f8:	00450513          	addi	a0,a0,4 # 800216f8 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	45e080e7          	jalr	1118(ra) # 80000b5a <initlock>
}
    80004704:	60a2                	ld	ra,8(sp)
    80004706:	6402                	ld	s0,0(sp)
    80004708:	0141                	addi	sp,sp,16
    8000470a:	8082                	ret

000000008000470c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000470c:	1101                	addi	sp,sp,-32
    8000470e:	ec06                	sd	ra,24(sp)
    80004710:	e822                	sd	s0,16(sp)
    80004712:	e426                	sd	s1,8(sp)
    80004714:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004716:	0001d517          	auipc	a0,0x1d
    8000471a:	fe250513          	addi	a0,a0,-30 # 800216f8 <ftable>
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	4cc080e7          	jalr	1228(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004726:	0001d497          	auipc	s1,0x1d
    8000472a:	fea48493          	addi	s1,s1,-22 # 80021710 <ftable+0x18>
    8000472e:	0001e717          	auipc	a4,0x1e
    80004732:	f8270713          	addi	a4,a4,-126 # 800226b0 <disk>
    if(f->ref == 0){
    80004736:	40dc                	lw	a5,4(s1)
    80004738:	cf99                	beqz	a5,80004756 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000473a:	02848493          	addi	s1,s1,40
    8000473e:	fee49ce3          	bne	s1,a4,80004736 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004742:	0001d517          	auipc	a0,0x1d
    80004746:	fb650513          	addi	a0,a0,-74 # 800216f8 <ftable>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	554080e7          	jalr	1364(ra) # 80000c9e <release>
  return 0;
    80004752:	4481                	li	s1,0
    80004754:	a819                	j	8000476a <filealloc+0x5e>
      f->ref = 1;
    80004756:	4785                	li	a5,1
    80004758:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000475a:	0001d517          	auipc	a0,0x1d
    8000475e:	f9e50513          	addi	a0,a0,-98 # 800216f8 <ftable>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	53c080e7          	jalr	1340(ra) # 80000c9e <release>
}
    8000476a:	8526                	mv	a0,s1
    8000476c:	60e2                	ld	ra,24(sp)
    8000476e:	6442                	ld	s0,16(sp)
    80004770:	64a2                	ld	s1,8(sp)
    80004772:	6105                	addi	sp,sp,32
    80004774:	8082                	ret

0000000080004776 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004776:	1101                	addi	sp,sp,-32
    80004778:	ec06                	sd	ra,24(sp)
    8000477a:	e822                	sd	s0,16(sp)
    8000477c:	e426                	sd	s1,8(sp)
    8000477e:	1000                	addi	s0,sp,32
    80004780:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004782:	0001d517          	auipc	a0,0x1d
    80004786:	f7650513          	addi	a0,a0,-138 # 800216f8 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	460080e7          	jalr	1120(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004792:	40dc                	lw	a5,4(s1)
    80004794:	02f05263          	blez	a5,800047b8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004798:	2785                	addiw	a5,a5,1
    8000479a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000479c:	0001d517          	auipc	a0,0x1d
    800047a0:	f5c50513          	addi	a0,a0,-164 # 800216f8 <ftable>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	4fa080e7          	jalr	1274(ra) # 80000c9e <release>
  return f;
}
    800047ac:	8526                	mv	a0,s1
    800047ae:	60e2                	ld	ra,24(sp)
    800047b0:	6442                	ld	s0,16(sp)
    800047b2:	64a2                	ld	s1,8(sp)
    800047b4:	6105                	addi	sp,sp,32
    800047b6:	8082                	ret
    panic("filedup");
    800047b8:	00004517          	auipc	a0,0x4
    800047bc:	08050513          	addi	a0,a0,128 # 80008838 <syscalls+0x258>
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	d84080e7          	jalr	-636(ra) # 80000544 <panic>

00000000800047c8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047c8:	7139                	addi	sp,sp,-64
    800047ca:	fc06                	sd	ra,56(sp)
    800047cc:	f822                	sd	s0,48(sp)
    800047ce:	f426                	sd	s1,40(sp)
    800047d0:	f04a                	sd	s2,32(sp)
    800047d2:	ec4e                	sd	s3,24(sp)
    800047d4:	e852                	sd	s4,16(sp)
    800047d6:	e456                	sd	s5,8(sp)
    800047d8:	0080                	addi	s0,sp,64
    800047da:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047dc:	0001d517          	auipc	a0,0x1d
    800047e0:	f1c50513          	addi	a0,a0,-228 # 800216f8 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	406080e7          	jalr	1030(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800047ec:	40dc                	lw	a5,4(s1)
    800047ee:	06f05163          	blez	a5,80004850 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047f2:	37fd                	addiw	a5,a5,-1
    800047f4:	0007871b          	sext.w	a4,a5
    800047f8:	c0dc                	sw	a5,4(s1)
    800047fa:	06e04363          	bgtz	a4,80004860 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047fe:	0004a903          	lw	s2,0(s1)
    80004802:	0094ca83          	lbu	s5,9(s1)
    80004806:	0104ba03          	ld	s4,16(s1)
    8000480a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000480e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004812:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004816:	0001d517          	auipc	a0,0x1d
    8000481a:	ee250513          	addi	a0,a0,-286 # 800216f8 <ftable>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	480080e7          	jalr	1152(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004826:	4785                	li	a5,1
    80004828:	04f90d63          	beq	s2,a5,80004882 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000482c:	3979                	addiw	s2,s2,-2
    8000482e:	4785                	li	a5,1
    80004830:	0527e063          	bltu	a5,s2,80004870 <fileclose+0xa8>
    begin_op();
    80004834:	00000097          	auipc	ra,0x0
    80004838:	ac8080e7          	jalr	-1336(ra) # 800042fc <begin_op>
    iput(ff.ip);
    8000483c:	854e                	mv	a0,s3
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	2b6080e7          	jalr	694(ra) # 80003af4 <iput>
    end_op();
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	b36080e7          	jalr	-1226(ra) # 8000437c <end_op>
    8000484e:	a00d                	j	80004870 <fileclose+0xa8>
    panic("fileclose");
    80004850:	00004517          	auipc	a0,0x4
    80004854:	ff050513          	addi	a0,a0,-16 # 80008840 <syscalls+0x260>
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	cec080e7          	jalr	-788(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004860:	0001d517          	auipc	a0,0x1d
    80004864:	e9850513          	addi	a0,a0,-360 # 800216f8 <ftable>
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	436080e7          	jalr	1078(ra) # 80000c9e <release>
  }
}
    80004870:	70e2                	ld	ra,56(sp)
    80004872:	7442                	ld	s0,48(sp)
    80004874:	74a2                	ld	s1,40(sp)
    80004876:	7902                	ld	s2,32(sp)
    80004878:	69e2                	ld	s3,24(sp)
    8000487a:	6a42                	ld	s4,16(sp)
    8000487c:	6aa2                	ld	s5,8(sp)
    8000487e:	6121                	addi	sp,sp,64
    80004880:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004882:	85d6                	mv	a1,s5
    80004884:	8552                	mv	a0,s4
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	34c080e7          	jalr	844(ra) # 80004bd2 <pipeclose>
    8000488e:	b7cd                	j	80004870 <fileclose+0xa8>

0000000080004890 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004890:	715d                	addi	sp,sp,-80
    80004892:	e486                	sd	ra,72(sp)
    80004894:	e0a2                	sd	s0,64(sp)
    80004896:	fc26                	sd	s1,56(sp)
    80004898:	f84a                	sd	s2,48(sp)
    8000489a:	f44e                	sd	s3,40(sp)
    8000489c:	0880                	addi	s0,sp,80
    8000489e:	84aa                	mv	s1,a0
    800048a0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048a2:	ffffd097          	auipc	ra,0xffffd
    800048a6:	124080e7          	jalr	292(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048aa:	409c                	lw	a5,0(s1)
    800048ac:	37f9                	addiw	a5,a5,-2
    800048ae:	4705                	li	a4,1
    800048b0:	04f76763          	bltu	a4,a5,800048fe <filestat+0x6e>
    800048b4:	892a                	mv	s2,a0
    ilock(f->ip);
    800048b6:	6c88                	ld	a0,24(s1)
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	082080e7          	jalr	130(ra) # 8000393a <ilock>
    stati(f->ip, &st);
    800048c0:	fb840593          	addi	a1,s0,-72
    800048c4:	6c88                	ld	a0,24(s1)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	2fe080e7          	jalr	766(ra) # 80003bc4 <stati>
    iunlock(f->ip);
    800048ce:	6c88                	ld	a0,24(s1)
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	12c080e7          	jalr	300(ra) # 800039fc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048d8:	46e1                	li	a3,24
    800048da:	fb840613          	addi	a2,s0,-72
    800048de:	85ce                	mv	a1,s3
    800048e0:	05093503          	ld	a0,80(s2)
    800048e4:	ffffd097          	auipc	ra,0xffffd
    800048e8:	da0080e7          	jalr	-608(ra) # 80001684 <copyout>
    800048ec:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048f0:	60a6                	ld	ra,72(sp)
    800048f2:	6406                	ld	s0,64(sp)
    800048f4:	74e2                	ld	s1,56(sp)
    800048f6:	7942                	ld	s2,48(sp)
    800048f8:	79a2                	ld	s3,40(sp)
    800048fa:	6161                	addi	sp,sp,80
    800048fc:	8082                	ret
  return -1;
    800048fe:	557d                	li	a0,-1
    80004900:	bfc5                	j	800048f0 <filestat+0x60>

0000000080004902 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004902:	7179                	addi	sp,sp,-48
    80004904:	f406                	sd	ra,40(sp)
    80004906:	f022                	sd	s0,32(sp)
    80004908:	ec26                	sd	s1,24(sp)
    8000490a:	e84a                	sd	s2,16(sp)
    8000490c:	e44e                	sd	s3,8(sp)
    8000490e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004910:	00854783          	lbu	a5,8(a0)
    80004914:	c3d5                	beqz	a5,800049b8 <fileread+0xb6>
    80004916:	84aa                	mv	s1,a0
    80004918:	89ae                	mv	s3,a1
    8000491a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000491c:	411c                	lw	a5,0(a0)
    8000491e:	4705                	li	a4,1
    80004920:	04e78963          	beq	a5,a4,80004972 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004924:	470d                	li	a4,3
    80004926:	04e78d63          	beq	a5,a4,80004980 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000492a:	4709                	li	a4,2
    8000492c:	06e79e63          	bne	a5,a4,800049a8 <fileread+0xa6>
    ilock(f->ip);
    80004930:	6d08                	ld	a0,24(a0)
    80004932:	fffff097          	auipc	ra,0xfffff
    80004936:	008080e7          	jalr	8(ra) # 8000393a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000493a:	874a                	mv	a4,s2
    8000493c:	5094                	lw	a3,32(s1)
    8000493e:	864e                	mv	a2,s3
    80004940:	4585                	li	a1,1
    80004942:	6c88                	ld	a0,24(s1)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	2aa080e7          	jalr	682(ra) # 80003bee <readi>
    8000494c:	892a                	mv	s2,a0
    8000494e:	00a05563          	blez	a0,80004958 <fileread+0x56>
      f->off += r;
    80004952:	509c                	lw	a5,32(s1)
    80004954:	9fa9                	addw	a5,a5,a0
    80004956:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004958:	6c88                	ld	a0,24(s1)
    8000495a:	fffff097          	auipc	ra,0xfffff
    8000495e:	0a2080e7          	jalr	162(ra) # 800039fc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004962:	854a                	mv	a0,s2
    80004964:	70a2                	ld	ra,40(sp)
    80004966:	7402                	ld	s0,32(sp)
    80004968:	64e2                	ld	s1,24(sp)
    8000496a:	6942                	ld	s2,16(sp)
    8000496c:	69a2                	ld	s3,8(sp)
    8000496e:	6145                	addi	sp,sp,48
    80004970:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004972:	6908                	ld	a0,16(a0)
    80004974:	00000097          	auipc	ra,0x0
    80004978:	3ce080e7          	jalr	974(ra) # 80004d42 <piperead>
    8000497c:	892a                	mv	s2,a0
    8000497e:	b7d5                	j	80004962 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004980:	02451783          	lh	a5,36(a0)
    80004984:	03079693          	slli	a3,a5,0x30
    80004988:	92c1                	srli	a3,a3,0x30
    8000498a:	4725                	li	a4,9
    8000498c:	02d76863          	bltu	a4,a3,800049bc <fileread+0xba>
    80004990:	0792                	slli	a5,a5,0x4
    80004992:	0001d717          	auipc	a4,0x1d
    80004996:	cc670713          	addi	a4,a4,-826 # 80021658 <devsw>
    8000499a:	97ba                	add	a5,a5,a4
    8000499c:	639c                	ld	a5,0(a5)
    8000499e:	c38d                	beqz	a5,800049c0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049a0:	4505                	li	a0,1
    800049a2:	9782                	jalr	a5
    800049a4:	892a                	mv	s2,a0
    800049a6:	bf75                	j	80004962 <fileread+0x60>
    panic("fileread");
    800049a8:	00004517          	auipc	a0,0x4
    800049ac:	ea850513          	addi	a0,a0,-344 # 80008850 <syscalls+0x270>
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	b94080e7          	jalr	-1132(ra) # 80000544 <panic>
    return -1;
    800049b8:	597d                	li	s2,-1
    800049ba:	b765                	j	80004962 <fileread+0x60>
      return -1;
    800049bc:	597d                	li	s2,-1
    800049be:	b755                	j	80004962 <fileread+0x60>
    800049c0:	597d                	li	s2,-1
    800049c2:	b745                	j	80004962 <fileread+0x60>

00000000800049c4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049c4:	715d                	addi	sp,sp,-80
    800049c6:	e486                	sd	ra,72(sp)
    800049c8:	e0a2                	sd	s0,64(sp)
    800049ca:	fc26                	sd	s1,56(sp)
    800049cc:	f84a                	sd	s2,48(sp)
    800049ce:	f44e                	sd	s3,40(sp)
    800049d0:	f052                	sd	s4,32(sp)
    800049d2:	ec56                	sd	s5,24(sp)
    800049d4:	e85a                	sd	s6,16(sp)
    800049d6:	e45e                	sd	s7,8(sp)
    800049d8:	e062                	sd	s8,0(sp)
    800049da:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049dc:	00954783          	lbu	a5,9(a0)
    800049e0:	10078663          	beqz	a5,80004aec <filewrite+0x128>
    800049e4:	892a                	mv	s2,a0
    800049e6:	8aae                	mv	s5,a1
    800049e8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049ea:	411c                	lw	a5,0(a0)
    800049ec:	4705                	li	a4,1
    800049ee:	02e78263          	beq	a5,a4,80004a12 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049f2:	470d                	li	a4,3
    800049f4:	02e78663          	beq	a5,a4,80004a20 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049f8:	4709                	li	a4,2
    800049fa:	0ee79163          	bne	a5,a4,80004adc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049fe:	0ac05d63          	blez	a2,80004ab8 <filewrite+0xf4>
    int i = 0;
    80004a02:	4981                	li	s3,0
    80004a04:	6b05                	lui	s6,0x1
    80004a06:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a0a:	6b85                	lui	s7,0x1
    80004a0c:	c00b8b9b          	addiw	s7,s7,-1024
    80004a10:	a861                	j	80004aa8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a12:	6908                	ld	a0,16(a0)
    80004a14:	00000097          	auipc	ra,0x0
    80004a18:	22e080e7          	jalr	558(ra) # 80004c42 <pipewrite>
    80004a1c:	8a2a                	mv	s4,a0
    80004a1e:	a045                	j	80004abe <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a20:	02451783          	lh	a5,36(a0)
    80004a24:	03079693          	slli	a3,a5,0x30
    80004a28:	92c1                	srli	a3,a3,0x30
    80004a2a:	4725                	li	a4,9
    80004a2c:	0cd76263          	bltu	a4,a3,80004af0 <filewrite+0x12c>
    80004a30:	0792                	slli	a5,a5,0x4
    80004a32:	0001d717          	auipc	a4,0x1d
    80004a36:	c2670713          	addi	a4,a4,-986 # 80021658 <devsw>
    80004a3a:	97ba                	add	a5,a5,a4
    80004a3c:	679c                	ld	a5,8(a5)
    80004a3e:	cbdd                	beqz	a5,80004af4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a40:	4505                	li	a0,1
    80004a42:	9782                	jalr	a5
    80004a44:	8a2a                	mv	s4,a0
    80004a46:	a8a5                	j	80004abe <filewrite+0xfa>
    80004a48:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a4c:	00000097          	auipc	ra,0x0
    80004a50:	8b0080e7          	jalr	-1872(ra) # 800042fc <begin_op>
      ilock(f->ip);
    80004a54:	01893503          	ld	a0,24(s2)
    80004a58:	fffff097          	auipc	ra,0xfffff
    80004a5c:	ee2080e7          	jalr	-286(ra) # 8000393a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a60:	8762                	mv	a4,s8
    80004a62:	02092683          	lw	a3,32(s2)
    80004a66:	01598633          	add	a2,s3,s5
    80004a6a:	4585                	li	a1,1
    80004a6c:	01893503          	ld	a0,24(s2)
    80004a70:	fffff097          	auipc	ra,0xfffff
    80004a74:	276080e7          	jalr	630(ra) # 80003ce6 <writei>
    80004a78:	84aa                	mv	s1,a0
    80004a7a:	00a05763          	blez	a0,80004a88 <filewrite+0xc4>
        f->off += r;
    80004a7e:	02092783          	lw	a5,32(s2)
    80004a82:	9fa9                	addw	a5,a5,a0
    80004a84:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a88:	01893503          	ld	a0,24(s2)
    80004a8c:	fffff097          	auipc	ra,0xfffff
    80004a90:	f70080e7          	jalr	-144(ra) # 800039fc <iunlock>
      end_op();
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	8e8080e7          	jalr	-1816(ra) # 8000437c <end_op>

      if(r != n1){
    80004a9c:	009c1f63          	bne	s8,s1,80004aba <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004aa0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aa4:	0149db63          	bge	s3,s4,80004aba <filewrite+0xf6>
      int n1 = n - i;
    80004aa8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aac:	84be                	mv	s1,a5
    80004aae:	2781                	sext.w	a5,a5
    80004ab0:	f8fb5ce3          	bge	s6,a5,80004a48 <filewrite+0x84>
    80004ab4:	84de                	mv	s1,s7
    80004ab6:	bf49                	j	80004a48 <filewrite+0x84>
    int i = 0;
    80004ab8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004aba:	013a1f63          	bne	s4,s3,80004ad8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004abe:	8552                	mv	a0,s4
    80004ac0:	60a6                	ld	ra,72(sp)
    80004ac2:	6406                	ld	s0,64(sp)
    80004ac4:	74e2                	ld	s1,56(sp)
    80004ac6:	7942                	ld	s2,48(sp)
    80004ac8:	79a2                	ld	s3,40(sp)
    80004aca:	7a02                	ld	s4,32(sp)
    80004acc:	6ae2                	ld	s5,24(sp)
    80004ace:	6b42                	ld	s6,16(sp)
    80004ad0:	6ba2                	ld	s7,8(sp)
    80004ad2:	6c02                	ld	s8,0(sp)
    80004ad4:	6161                	addi	sp,sp,80
    80004ad6:	8082                	ret
    ret = (i == n ? n : -1);
    80004ad8:	5a7d                	li	s4,-1
    80004ada:	b7d5                	j	80004abe <filewrite+0xfa>
    panic("filewrite");
    80004adc:	00004517          	auipc	a0,0x4
    80004ae0:	d8450513          	addi	a0,a0,-636 # 80008860 <syscalls+0x280>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	a60080e7          	jalr	-1440(ra) # 80000544 <panic>
    return -1;
    80004aec:	5a7d                	li	s4,-1
    80004aee:	bfc1                	j	80004abe <filewrite+0xfa>
      return -1;
    80004af0:	5a7d                	li	s4,-1
    80004af2:	b7f1                	j	80004abe <filewrite+0xfa>
    80004af4:	5a7d                	li	s4,-1
    80004af6:	b7e1                	j	80004abe <filewrite+0xfa>

0000000080004af8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004af8:	7179                	addi	sp,sp,-48
    80004afa:	f406                	sd	ra,40(sp)
    80004afc:	f022                	sd	s0,32(sp)
    80004afe:	ec26                	sd	s1,24(sp)
    80004b00:	e84a                	sd	s2,16(sp)
    80004b02:	e44e                	sd	s3,8(sp)
    80004b04:	e052                	sd	s4,0(sp)
    80004b06:	1800                	addi	s0,sp,48
    80004b08:	84aa                	mv	s1,a0
    80004b0a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b0c:	0005b023          	sd	zero,0(a1)
    80004b10:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b14:	00000097          	auipc	ra,0x0
    80004b18:	bf8080e7          	jalr	-1032(ra) # 8000470c <filealloc>
    80004b1c:	e088                	sd	a0,0(s1)
    80004b1e:	c551                	beqz	a0,80004baa <pipealloc+0xb2>
    80004b20:	00000097          	auipc	ra,0x0
    80004b24:	bec080e7          	jalr	-1044(ra) # 8000470c <filealloc>
    80004b28:	00aa3023          	sd	a0,0(s4)
    80004b2c:	c92d                	beqz	a0,80004b9e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	fcc080e7          	jalr	-52(ra) # 80000afa <kalloc>
    80004b36:	892a                	mv	s2,a0
    80004b38:	c125                	beqz	a0,80004b98 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b3a:	4985                	li	s3,1
    80004b3c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b40:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b44:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b48:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b4c:	00004597          	auipc	a1,0x4
    80004b50:	9ec58593          	addi	a1,a1,-1556 # 80008538 <states.1728+0x270>
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	006080e7          	jalr	6(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004b5c:	609c                	ld	a5,0(s1)
    80004b5e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b62:	609c                	ld	a5,0(s1)
    80004b64:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b68:	609c                	ld	a5,0(s1)
    80004b6a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b6e:	609c                	ld	a5,0(s1)
    80004b70:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b74:	000a3783          	ld	a5,0(s4)
    80004b78:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b7c:	000a3783          	ld	a5,0(s4)
    80004b80:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b84:	000a3783          	ld	a5,0(s4)
    80004b88:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b8c:	000a3783          	ld	a5,0(s4)
    80004b90:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b94:	4501                	li	a0,0
    80004b96:	a025                	j	80004bbe <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b98:	6088                	ld	a0,0(s1)
    80004b9a:	e501                	bnez	a0,80004ba2 <pipealloc+0xaa>
    80004b9c:	a039                	j	80004baa <pipealloc+0xb2>
    80004b9e:	6088                	ld	a0,0(s1)
    80004ba0:	c51d                	beqz	a0,80004bce <pipealloc+0xd6>
    fileclose(*f0);
    80004ba2:	00000097          	auipc	ra,0x0
    80004ba6:	c26080e7          	jalr	-986(ra) # 800047c8 <fileclose>
  if(*f1)
    80004baa:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bae:	557d                	li	a0,-1
  if(*f1)
    80004bb0:	c799                	beqz	a5,80004bbe <pipealloc+0xc6>
    fileclose(*f1);
    80004bb2:	853e                	mv	a0,a5
    80004bb4:	00000097          	auipc	ra,0x0
    80004bb8:	c14080e7          	jalr	-1004(ra) # 800047c8 <fileclose>
  return -1;
    80004bbc:	557d                	li	a0,-1
}
    80004bbe:	70a2                	ld	ra,40(sp)
    80004bc0:	7402                	ld	s0,32(sp)
    80004bc2:	64e2                	ld	s1,24(sp)
    80004bc4:	6942                	ld	s2,16(sp)
    80004bc6:	69a2                	ld	s3,8(sp)
    80004bc8:	6a02                	ld	s4,0(sp)
    80004bca:	6145                	addi	sp,sp,48
    80004bcc:	8082                	ret
  return -1;
    80004bce:	557d                	li	a0,-1
    80004bd0:	b7fd                	j	80004bbe <pipealloc+0xc6>

0000000080004bd2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bd2:	1101                	addi	sp,sp,-32
    80004bd4:	ec06                	sd	ra,24(sp)
    80004bd6:	e822                	sd	s0,16(sp)
    80004bd8:	e426                	sd	s1,8(sp)
    80004bda:	e04a                	sd	s2,0(sp)
    80004bdc:	1000                	addi	s0,sp,32
    80004bde:	84aa                	mv	s1,a0
    80004be0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	008080e7          	jalr	8(ra) # 80000bea <acquire>
  if(writable){
    80004bea:	02090d63          	beqz	s2,80004c24 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bee:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bf2:	21848513          	addi	a0,s1,536
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	514080e7          	jalr	1300(ra) # 8000210a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bfe:	2204b783          	ld	a5,544(s1)
    80004c02:	eb95                	bnez	a5,80004c36 <pipeclose+0x64>
    release(&pi->lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	098080e7          	jalr	152(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004c0e:	8526                	mv	a0,s1
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	dee080e7          	jalr	-530(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004c18:	60e2                	ld	ra,24(sp)
    80004c1a:	6442                	ld	s0,16(sp)
    80004c1c:	64a2                	ld	s1,8(sp)
    80004c1e:	6902                	ld	s2,0(sp)
    80004c20:	6105                	addi	sp,sp,32
    80004c22:	8082                	ret
    pi->readopen = 0;
    80004c24:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c28:	21c48513          	addi	a0,s1,540
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	4de080e7          	jalr	1246(ra) # 8000210a <wakeup>
    80004c34:	b7e9                	j	80004bfe <pipeclose+0x2c>
    release(&pi->lock);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	066080e7          	jalr	102(ra) # 80000c9e <release>
}
    80004c40:	bfe1                	j	80004c18 <pipeclose+0x46>

0000000080004c42 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c42:	7159                	addi	sp,sp,-112
    80004c44:	f486                	sd	ra,104(sp)
    80004c46:	f0a2                	sd	s0,96(sp)
    80004c48:	eca6                	sd	s1,88(sp)
    80004c4a:	e8ca                	sd	s2,80(sp)
    80004c4c:	e4ce                	sd	s3,72(sp)
    80004c4e:	e0d2                	sd	s4,64(sp)
    80004c50:	fc56                	sd	s5,56(sp)
    80004c52:	f85a                	sd	s6,48(sp)
    80004c54:	f45e                	sd	s7,40(sp)
    80004c56:	f062                	sd	s8,32(sp)
    80004c58:	ec66                	sd	s9,24(sp)
    80004c5a:	1880                	addi	s0,sp,112
    80004c5c:	84aa                	mv	s1,a0
    80004c5e:	8aae                	mv	s5,a1
    80004c60:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	d64080e7          	jalr	-668(ra) # 800019c6 <myproc>
    80004c6a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	f7c080e7          	jalr	-132(ra) # 80000bea <acquire>
  while(i < n){
    80004c76:	0d405463          	blez	s4,80004d3e <pipewrite+0xfc>
    80004c7a:	8ba6                	mv	s7,s1
  int i = 0;
    80004c7c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c7e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c80:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c84:	21c48c13          	addi	s8,s1,540
    80004c88:	a08d                	j	80004cea <pipewrite+0xa8>
      release(&pi->lock);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	012080e7          	jalr	18(ra) # 80000c9e <release>
      return -1;
    80004c94:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c96:	854a                	mv	a0,s2
    80004c98:	70a6                	ld	ra,104(sp)
    80004c9a:	7406                	ld	s0,96(sp)
    80004c9c:	64e6                	ld	s1,88(sp)
    80004c9e:	6946                	ld	s2,80(sp)
    80004ca0:	69a6                	ld	s3,72(sp)
    80004ca2:	6a06                	ld	s4,64(sp)
    80004ca4:	7ae2                	ld	s5,56(sp)
    80004ca6:	7b42                	ld	s6,48(sp)
    80004ca8:	7ba2                	ld	s7,40(sp)
    80004caa:	7c02                	ld	s8,32(sp)
    80004cac:	6ce2                	ld	s9,24(sp)
    80004cae:	6165                	addi	sp,sp,112
    80004cb0:	8082                	ret
      wakeup(&pi->nread);
    80004cb2:	8566                	mv	a0,s9
    80004cb4:	ffffd097          	auipc	ra,0xffffd
    80004cb8:	456080e7          	jalr	1110(ra) # 8000210a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cbc:	85de                	mv	a1,s7
    80004cbe:	8562                	mv	a0,s8
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	3e6080e7          	jalr	998(ra) # 800020a6 <sleep>
    80004cc8:	a839                	j	80004ce6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cca:	21c4a783          	lw	a5,540(s1)
    80004cce:	0017871b          	addiw	a4,a5,1
    80004cd2:	20e4ae23          	sw	a4,540(s1)
    80004cd6:	1ff7f793          	andi	a5,a5,511
    80004cda:	97a6                	add	a5,a5,s1
    80004cdc:	f9f44703          	lbu	a4,-97(s0)
    80004ce0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ce4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ce6:	05495063          	bge	s2,s4,80004d26 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004cea:	2204a783          	lw	a5,544(s1)
    80004cee:	dfd1                	beqz	a5,80004c8a <pipewrite+0x48>
    80004cf0:	854e                	mv	a0,s3
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	65c080e7          	jalr	1628(ra) # 8000234e <killed>
    80004cfa:	f941                	bnez	a0,80004c8a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004cfc:	2184a783          	lw	a5,536(s1)
    80004d00:	21c4a703          	lw	a4,540(s1)
    80004d04:	2007879b          	addiw	a5,a5,512
    80004d08:	faf705e3          	beq	a4,a5,80004cb2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d0c:	4685                	li	a3,1
    80004d0e:	01590633          	add	a2,s2,s5
    80004d12:	f9f40593          	addi	a1,s0,-97
    80004d16:	0509b503          	ld	a0,80(s3)
    80004d1a:	ffffd097          	auipc	ra,0xffffd
    80004d1e:	9f6080e7          	jalr	-1546(ra) # 80001710 <copyin>
    80004d22:	fb6514e3          	bne	a0,s6,80004cca <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d26:	21848513          	addi	a0,s1,536
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	3e0080e7          	jalr	992(ra) # 8000210a <wakeup>
  release(&pi->lock);
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	f6a080e7          	jalr	-150(ra) # 80000c9e <release>
  return i;
    80004d3c:	bfa9                	j	80004c96 <pipewrite+0x54>
  int i = 0;
    80004d3e:	4901                	li	s2,0
    80004d40:	b7dd                	j	80004d26 <pipewrite+0xe4>

0000000080004d42 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d42:	715d                	addi	sp,sp,-80
    80004d44:	e486                	sd	ra,72(sp)
    80004d46:	e0a2                	sd	s0,64(sp)
    80004d48:	fc26                	sd	s1,56(sp)
    80004d4a:	f84a                	sd	s2,48(sp)
    80004d4c:	f44e                	sd	s3,40(sp)
    80004d4e:	f052                	sd	s4,32(sp)
    80004d50:	ec56                	sd	s5,24(sp)
    80004d52:	e85a                	sd	s6,16(sp)
    80004d54:	0880                	addi	s0,sp,80
    80004d56:	84aa                	mv	s1,a0
    80004d58:	892e                	mv	s2,a1
    80004d5a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	c6a080e7          	jalr	-918(ra) # 800019c6 <myproc>
    80004d64:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d66:	8b26                	mv	s6,s1
    80004d68:	8526                	mv	a0,s1
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	e80080e7          	jalr	-384(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d72:	2184a703          	lw	a4,536(s1)
    80004d76:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d7a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d7e:	02f71763          	bne	a4,a5,80004dac <piperead+0x6a>
    80004d82:	2244a783          	lw	a5,548(s1)
    80004d86:	c39d                	beqz	a5,80004dac <piperead+0x6a>
    if(killed(pr)){
    80004d88:	8552                	mv	a0,s4
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	5c4080e7          	jalr	1476(ra) # 8000234e <killed>
    80004d92:	e941                	bnez	a0,80004e22 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d94:	85da                	mv	a1,s6
    80004d96:	854e                	mv	a0,s3
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	30e080e7          	jalr	782(ra) # 800020a6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004da0:	2184a703          	lw	a4,536(s1)
    80004da4:	21c4a783          	lw	a5,540(s1)
    80004da8:	fcf70de3          	beq	a4,a5,80004d82 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dac:	09505263          	blez	s5,80004e30 <piperead+0xee>
    80004db0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004db2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004db4:	2184a783          	lw	a5,536(s1)
    80004db8:	21c4a703          	lw	a4,540(s1)
    80004dbc:	02f70d63          	beq	a4,a5,80004df6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dc0:	0017871b          	addiw	a4,a5,1
    80004dc4:	20e4ac23          	sw	a4,536(s1)
    80004dc8:	1ff7f793          	andi	a5,a5,511
    80004dcc:	97a6                	add	a5,a5,s1
    80004dce:	0187c783          	lbu	a5,24(a5)
    80004dd2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd6:	4685                	li	a3,1
    80004dd8:	fbf40613          	addi	a2,s0,-65
    80004ddc:	85ca                	mv	a1,s2
    80004dde:	050a3503          	ld	a0,80(s4)
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	8a2080e7          	jalr	-1886(ra) # 80001684 <copyout>
    80004dea:	01650663          	beq	a0,s6,80004df6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dee:	2985                	addiw	s3,s3,1
    80004df0:	0905                	addi	s2,s2,1
    80004df2:	fd3a91e3          	bne	s5,s3,80004db4 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004df6:	21c48513          	addi	a0,s1,540
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	310080e7          	jalr	784(ra) # 8000210a <wakeup>
  release(&pi->lock);
    80004e02:	8526                	mv	a0,s1
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	e9a080e7          	jalr	-358(ra) # 80000c9e <release>
  return i;
}
    80004e0c:	854e                	mv	a0,s3
    80004e0e:	60a6                	ld	ra,72(sp)
    80004e10:	6406                	ld	s0,64(sp)
    80004e12:	74e2                	ld	s1,56(sp)
    80004e14:	7942                	ld	s2,48(sp)
    80004e16:	79a2                	ld	s3,40(sp)
    80004e18:	7a02                	ld	s4,32(sp)
    80004e1a:	6ae2                	ld	s5,24(sp)
    80004e1c:	6b42                	ld	s6,16(sp)
    80004e1e:	6161                	addi	sp,sp,80
    80004e20:	8082                	ret
      release(&pi->lock);
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	e7a080e7          	jalr	-390(ra) # 80000c9e <release>
      return -1;
    80004e2c:	59fd                	li	s3,-1
    80004e2e:	bff9                	j	80004e0c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e30:	4981                	li	s3,0
    80004e32:	b7d1                	j	80004df6 <piperead+0xb4>

0000000080004e34 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e34:	1141                	addi	sp,sp,-16
    80004e36:	e422                	sd	s0,8(sp)
    80004e38:	0800                	addi	s0,sp,16
    80004e3a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e3c:	8905                	andi	a0,a0,1
    80004e3e:	c111                	beqz	a0,80004e42 <flags2perm+0xe>
      perm = PTE_X;
    80004e40:	4521                	li	a0,8
    if(flags & 0x2)
    80004e42:	8b89                	andi	a5,a5,2
    80004e44:	c399                	beqz	a5,80004e4a <flags2perm+0x16>
      perm |= PTE_W;
    80004e46:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e4a:	6422                	ld	s0,8(sp)
    80004e4c:	0141                	addi	sp,sp,16
    80004e4e:	8082                	ret

0000000080004e50 <exec>:

int
exec(char *path, char **argv)
{
    80004e50:	df010113          	addi	sp,sp,-528
    80004e54:	20113423          	sd	ra,520(sp)
    80004e58:	20813023          	sd	s0,512(sp)
    80004e5c:	ffa6                	sd	s1,504(sp)
    80004e5e:	fbca                	sd	s2,496(sp)
    80004e60:	f7ce                	sd	s3,488(sp)
    80004e62:	f3d2                	sd	s4,480(sp)
    80004e64:	efd6                	sd	s5,472(sp)
    80004e66:	ebda                	sd	s6,464(sp)
    80004e68:	e7de                	sd	s7,456(sp)
    80004e6a:	e3e2                	sd	s8,448(sp)
    80004e6c:	ff66                	sd	s9,440(sp)
    80004e6e:	fb6a                	sd	s10,432(sp)
    80004e70:	f76e                	sd	s11,424(sp)
    80004e72:	0c00                	addi	s0,sp,528
    80004e74:	84aa                	mv	s1,a0
    80004e76:	dea43c23          	sd	a0,-520(s0)
    80004e7a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	b48080e7          	jalr	-1208(ra) # 800019c6 <myproc>
    80004e86:	892a                	mv	s2,a0

  begin_op();
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	474080e7          	jalr	1140(ra) # 800042fc <begin_op>

  if((ip = namei(path)) == 0){
    80004e90:	8526                	mv	a0,s1
    80004e92:	fffff097          	auipc	ra,0xfffff
    80004e96:	24e080e7          	jalr	590(ra) # 800040e0 <namei>
    80004e9a:	c92d                	beqz	a0,80004f0c <exec+0xbc>
    80004e9c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e9e:	fffff097          	auipc	ra,0xfffff
    80004ea2:	a9c080e7          	jalr	-1380(ra) # 8000393a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ea6:	04000713          	li	a4,64
    80004eaa:	4681                	li	a3,0
    80004eac:	e5040613          	addi	a2,s0,-432
    80004eb0:	4581                	li	a1,0
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	d3a080e7          	jalr	-710(ra) # 80003bee <readi>
    80004ebc:	04000793          	li	a5,64
    80004ec0:	00f51a63          	bne	a0,a5,80004ed4 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004ec4:	e5042703          	lw	a4,-432(s0)
    80004ec8:	464c47b7          	lui	a5,0x464c4
    80004ecc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ed0:	04f70463          	beq	a4,a5,80004f18 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	cc6080e7          	jalr	-826(ra) # 80003b9c <iunlockput>
    end_op();
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	49e080e7          	jalr	1182(ra) # 8000437c <end_op>
  }
  return -1;
    80004ee6:	557d                	li	a0,-1
}
    80004ee8:	20813083          	ld	ra,520(sp)
    80004eec:	20013403          	ld	s0,512(sp)
    80004ef0:	74fe                	ld	s1,504(sp)
    80004ef2:	795e                	ld	s2,496(sp)
    80004ef4:	79be                	ld	s3,488(sp)
    80004ef6:	7a1e                	ld	s4,480(sp)
    80004ef8:	6afe                	ld	s5,472(sp)
    80004efa:	6b5e                	ld	s6,464(sp)
    80004efc:	6bbe                	ld	s7,456(sp)
    80004efe:	6c1e                	ld	s8,448(sp)
    80004f00:	7cfa                	ld	s9,440(sp)
    80004f02:	7d5a                	ld	s10,432(sp)
    80004f04:	7dba                	ld	s11,424(sp)
    80004f06:	21010113          	addi	sp,sp,528
    80004f0a:	8082                	ret
    end_op();
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	470080e7          	jalr	1136(ra) # 8000437c <end_op>
    return -1;
    80004f14:	557d                	li	a0,-1
    80004f16:	bfc9                	j	80004ee8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f18:	854a                	mv	a0,s2
    80004f1a:	ffffd097          	auipc	ra,0xffffd
    80004f1e:	b70080e7          	jalr	-1168(ra) # 80001a8a <proc_pagetable>
    80004f22:	8baa                	mv	s7,a0
    80004f24:	d945                	beqz	a0,80004ed4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f26:	e7042983          	lw	s3,-400(s0)
    80004f2a:	e8845783          	lhu	a5,-376(s0)
    80004f2e:	c7ad                	beqz	a5,80004f98 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f30:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f32:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f34:	6c85                	lui	s9,0x1
    80004f36:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f3a:	def43823          	sd	a5,-528(s0)
    80004f3e:	ac0d                	j	80005170 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f40:	00004517          	auipc	a0,0x4
    80004f44:	93050513          	addi	a0,a0,-1744 # 80008870 <syscalls+0x290>
    80004f48:	ffffb097          	auipc	ra,0xffffb
    80004f4c:	5fc080e7          	jalr	1532(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f50:	8756                	mv	a4,s5
    80004f52:	012d86bb          	addw	a3,s11,s2
    80004f56:	4581                	li	a1,0
    80004f58:	8526                	mv	a0,s1
    80004f5a:	fffff097          	auipc	ra,0xfffff
    80004f5e:	c94080e7          	jalr	-876(ra) # 80003bee <readi>
    80004f62:	2501                	sext.w	a0,a0
    80004f64:	1aaa9a63          	bne	s5,a0,80005118 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004f68:	6785                	lui	a5,0x1
    80004f6a:	0127893b          	addw	s2,a5,s2
    80004f6e:	77fd                	lui	a5,0xfffff
    80004f70:	01478a3b          	addw	s4,a5,s4
    80004f74:	1f897563          	bgeu	s2,s8,8000515e <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004f78:	02091593          	slli	a1,s2,0x20
    80004f7c:	9181                	srli	a1,a1,0x20
    80004f7e:	95ea                	add	a1,a1,s10
    80004f80:	855e                	mv	a0,s7
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	0f6080e7          	jalr	246(ra) # 80001078 <walkaddr>
    80004f8a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f8c:	d955                	beqz	a0,80004f40 <exec+0xf0>
      n = PGSIZE;
    80004f8e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f90:	fd9a70e3          	bgeu	s4,s9,80004f50 <exec+0x100>
      n = sz - i;
    80004f94:	8ad2                	mv	s5,s4
    80004f96:	bf6d                	j	80004f50 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f98:	4a01                	li	s4,0
  iunlockput(ip);
    80004f9a:	8526                	mv	a0,s1
    80004f9c:	fffff097          	auipc	ra,0xfffff
    80004fa0:	c00080e7          	jalr	-1024(ra) # 80003b9c <iunlockput>
  end_op();
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	3d8080e7          	jalr	984(ra) # 8000437c <end_op>
  p = myproc();
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	a1a080e7          	jalr	-1510(ra) # 800019c6 <myproc>
    80004fb4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fb6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fba:	6785                	lui	a5,0x1
    80004fbc:	17fd                	addi	a5,a5,-1
    80004fbe:	9a3e                	add	s4,s4,a5
    80004fc0:	757d                	lui	a0,0xfffff
    80004fc2:	00aa77b3          	and	a5,s4,a0
    80004fc6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fca:	4691                	li	a3,4
    80004fcc:	6609                	lui	a2,0x2
    80004fce:	963e                	add	a2,a2,a5
    80004fd0:	85be                	mv	a1,a5
    80004fd2:	855e                	mv	a0,s7
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	458080e7          	jalr	1112(ra) # 8000142c <uvmalloc>
    80004fdc:	8b2a                	mv	s6,a0
  ip = 0;
    80004fde:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fe0:	12050c63          	beqz	a0,80005118 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fe4:	75f9                	lui	a1,0xffffe
    80004fe6:	95aa                	add	a1,a1,a0
    80004fe8:	855e                	mv	a0,s7
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	668080e7          	jalr	1640(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ff2:	7c7d                	lui	s8,0xfffff
    80004ff4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ff6:	e0043783          	ld	a5,-512(s0)
    80004ffa:	6388                	ld	a0,0(a5)
    80004ffc:	c535                	beqz	a0,80005068 <exec+0x218>
    80004ffe:	e9040993          	addi	s3,s0,-368
    80005002:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005006:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	e62080e7          	jalr	-414(ra) # 80000e6a <strlen>
    80005010:	2505                	addiw	a0,a0,1
    80005012:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005016:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000501a:	13896663          	bltu	s2,s8,80005146 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000501e:	e0043d83          	ld	s11,-512(s0)
    80005022:	000dba03          	ld	s4,0(s11)
    80005026:	8552                	mv	a0,s4
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	e42080e7          	jalr	-446(ra) # 80000e6a <strlen>
    80005030:	0015069b          	addiw	a3,a0,1
    80005034:	8652                	mv	a2,s4
    80005036:	85ca                	mv	a1,s2
    80005038:	855e                	mv	a0,s7
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	64a080e7          	jalr	1610(ra) # 80001684 <copyout>
    80005042:	10054663          	bltz	a0,8000514e <exec+0x2fe>
    ustack[argc] = sp;
    80005046:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000504a:	0485                	addi	s1,s1,1
    8000504c:	008d8793          	addi	a5,s11,8
    80005050:	e0f43023          	sd	a5,-512(s0)
    80005054:	008db503          	ld	a0,8(s11)
    80005058:	c911                	beqz	a0,8000506c <exec+0x21c>
    if(argc >= MAXARG)
    8000505a:	09a1                	addi	s3,s3,8
    8000505c:	fb3c96e3          	bne	s9,s3,80005008 <exec+0x1b8>
  sz = sz1;
    80005060:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005064:	4481                	li	s1,0
    80005066:	a84d                	j	80005118 <exec+0x2c8>
  sp = sz;
    80005068:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000506a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000506c:	00349793          	slli	a5,s1,0x3
    80005070:	f9040713          	addi	a4,s0,-112
    80005074:	97ba                	add	a5,a5,a4
    80005076:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000507a:	00148693          	addi	a3,s1,1
    8000507e:	068e                	slli	a3,a3,0x3
    80005080:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005084:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005088:	01897663          	bgeu	s2,s8,80005094 <exec+0x244>
  sz = sz1;
    8000508c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005090:	4481                	li	s1,0
    80005092:	a059                	j	80005118 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005094:	e9040613          	addi	a2,s0,-368
    80005098:	85ca                	mv	a1,s2
    8000509a:	855e                	mv	a0,s7
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	5e8080e7          	jalr	1512(ra) # 80001684 <copyout>
    800050a4:	0a054963          	bltz	a0,80005156 <exec+0x306>
  p->trapframe->a1 = sp;
    800050a8:	058ab783          	ld	a5,88(s5)
    800050ac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050b0:	df843783          	ld	a5,-520(s0)
    800050b4:	0007c703          	lbu	a4,0(a5)
    800050b8:	cf11                	beqz	a4,800050d4 <exec+0x284>
    800050ba:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050bc:	02f00693          	li	a3,47
    800050c0:	a039                	j	800050ce <exec+0x27e>
      last = s+1;
    800050c2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050c6:	0785                	addi	a5,a5,1
    800050c8:	fff7c703          	lbu	a4,-1(a5)
    800050cc:	c701                	beqz	a4,800050d4 <exec+0x284>
    if(*s == '/')
    800050ce:	fed71ce3          	bne	a4,a3,800050c6 <exec+0x276>
    800050d2:	bfc5                	j	800050c2 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800050d4:	4641                	li	a2,16
    800050d6:	df843583          	ld	a1,-520(s0)
    800050da:	158a8513          	addi	a0,s5,344
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	d5a080e7          	jalr	-678(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    800050e6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800050ea:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800050ee:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050f2:	058ab783          	ld	a5,88(s5)
    800050f6:	e6843703          	ld	a4,-408(s0)
    800050fa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050fc:	058ab783          	ld	a5,88(s5)
    80005100:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005104:	85ea                	mv	a1,s10
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	a20080e7          	jalr	-1504(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000510e:	0004851b          	sext.w	a0,s1
    80005112:	bbd9                	j	80004ee8 <exec+0x98>
    80005114:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005118:	e0843583          	ld	a1,-504(s0)
    8000511c:	855e                	mv	a0,s7
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	a08080e7          	jalr	-1528(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80005126:	da0497e3          	bnez	s1,80004ed4 <exec+0x84>
  return -1;
    8000512a:	557d                	li	a0,-1
    8000512c:	bb75                	j	80004ee8 <exec+0x98>
    8000512e:	e1443423          	sd	s4,-504(s0)
    80005132:	b7dd                	j	80005118 <exec+0x2c8>
    80005134:	e1443423          	sd	s4,-504(s0)
    80005138:	b7c5                	j	80005118 <exec+0x2c8>
    8000513a:	e1443423          	sd	s4,-504(s0)
    8000513e:	bfe9                	j	80005118 <exec+0x2c8>
    80005140:	e1443423          	sd	s4,-504(s0)
    80005144:	bfd1                	j	80005118 <exec+0x2c8>
  sz = sz1;
    80005146:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000514a:	4481                	li	s1,0
    8000514c:	b7f1                	j	80005118 <exec+0x2c8>
  sz = sz1;
    8000514e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005152:	4481                	li	s1,0
    80005154:	b7d1                	j	80005118 <exec+0x2c8>
  sz = sz1;
    80005156:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000515a:	4481                	li	s1,0
    8000515c:	bf75                	j	80005118 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000515e:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005162:	2b05                	addiw	s6,s6,1
    80005164:	0389899b          	addiw	s3,s3,56
    80005168:	e8845783          	lhu	a5,-376(s0)
    8000516c:	e2fb57e3          	bge	s6,a5,80004f9a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005170:	2981                	sext.w	s3,s3
    80005172:	03800713          	li	a4,56
    80005176:	86ce                	mv	a3,s3
    80005178:	e1840613          	addi	a2,s0,-488
    8000517c:	4581                	li	a1,0
    8000517e:	8526                	mv	a0,s1
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	a6e080e7          	jalr	-1426(ra) # 80003bee <readi>
    80005188:	03800793          	li	a5,56
    8000518c:	f8f514e3          	bne	a0,a5,80005114 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005190:	e1842783          	lw	a5,-488(s0)
    80005194:	4705                	li	a4,1
    80005196:	fce796e3          	bne	a5,a4,80005162 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000519a:	e4043903          	ld	s2,-448(s0)
    8000519e:	e3843783          	ld	a5,-456(s0)
    800051a2:	f8f966e3          	bltu	s2,a5,8000512e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051a6:	e2843783          	ld	a5,-472(s0)
    800051aa:	993e                	add	s2,s2,a5
    800051ac:	f8f964e3          	bltu	s2,a5,80005134 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800051b0:	df043703          	ld	a4,-528(s0)
    800051b4:	8ff9                	and	a5,a5,a4
    800051b6:	f3d1                	bnez	a5,8000513a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051b8:	e1c42503          	lw	a0,-484(s0)
    800051bc:	00000097          	auipc	ra,0x0
    800051c0:	c78080e7          	jalr	-904(ra) # 80004e34 <flags2perm>
    800051c4:	86aa                	mv	a3,a0
    800051c6:	864a                	mv	a2,s2
    800051c8:	85d2                	mv	a1,s4
    800051ca:	855e                	mv	a0,s7
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	260080e7          	jalr	608(ra) # 8000142c <uvmalloc>
    800051d4:	e0a43423          	sd	a0,-504(s0)
    800051d8:	d525                	beqz	a0,80005140 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051da:	e2843d03          	ld	s10,-472(s0)
    800051de:	e2042d83          	lw	s11,-480(s0)
    800051e2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051e6:	f60c0ce3          	beqz	s8,8000515e <exec+0x30e>
    800051ea:	8a62                	mv	s4,s8
    800051ec:	4901                	li	s2,0
    800051ee:	b369                	j	80004f78 <exec+0x128>

00000000800051f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051f0:	7179                	addi	sp,sp,-48
    800051f2:	f406                	sd	ra,40(sp)
    800051f4:	f022                	sd	s0,32(sp)
    800051f6:	ec26                	sd	s1,24(sp)
    800051f8:	e84a                	sd	s2,16(sp)
    800051fa:	1800                	addi	s0,sp,48
    800051fc:	892e                	mv	s2,a1
    800051fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005200:	fdc40593          	addi	a1,s0,-36
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	96a080e7          	jalr	-1686(ra) # 80002b6e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000520c:	fdc42703          	lw	a4,-36(s0)
    80005210:	47bd                	li	a5,15
    80005212:	02e7eb63          	bltu	a5,a4,80005248 <argfd+0x58>
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	7b0080e7          	jalr	1968(ra) # 800019c6 <myproc>
    8000521e:	fdc42703          	lw	a4,-36(s0)
    80005222:	01a70793          	addi	a5,a4,26
    80005226:	078e                	slli	a5,a5,0x3
    80005228:	953e                	add	a0,a0,a5
    8000522a:	611c                	ld	a5,0(a0)
    8000522c:	c385                	beqz	a5,8000524c <argfd+0x5c>
    return -1;
  if(pfd)
    8000522e:	00090463          	beqz	s2,80005236 <argfd+0x46>
    *pfd = fd;
    80005232:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005236:	4501                	li	a0,0
  if(pf)
    80005238:	c091                	beqz	s1,8000523c <argfd+0x4c>
    *pf = f;
    8000523a:	e09c                	sd	a5,0(s1)
}
    8000523c:	70a2                	ld	ra,40(sp)
    8000523e:	7402                	ld	s0,32(sp)
    80005240:	64e2                	ld	s1,24(sp)
    80005242:	6942                	ld	s2,16(sp)
    80005244:	6145                	addi	sp,sp,48
    80005246:	8082                	ret
    return -1;
    80005248:	557d                	li	a0,-1
    8000524a:	bfcd                	j	8000523c <argfd+0x4c>
    8000524c:	557d                	li	a0,-1
    8000524e:	b7fd                	j	8000523c <argfd+0x4c>

0000000080005250 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005250:	1101                	addi	sp,sp,-32
    80005252:	ec06                	sd	ra,24(sp)
    80005254:	e822                	sd	s0,16(sp)
    80005256:	e426                	sd	s1,8(sp)
    80005258:	1000                	addi	s0,sp,32
    8000525a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	76a080e7          	jalr	1898(ra) # 800019c6 <myproc>
    80005264:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005266:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdc8e0>
    8000526a:	4501                	li	a0,0
    8000526c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000526e:	6398                	ld	a4,0(a5)
    80005270:	cb19                	beqz	a4,80005286 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005272:	2505                	addiw	a0,a0,1
    80005274:	07a1                	addi	a5,a5,8
    80005276:	fed51ce3          	bne	a0,a3,8000526e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000527a:	557d                	li	a0,-1
}
    8000527c:	60e2                	ld	ra,24(sp)
    8000527e:	6442                	ld	s0,16(sp)
    80005280:	64a2                	ld	s1,8(sp)
    80005282:	6105                	addi	sp,sp,32
    80005284:	8082                	ret
      p->ofile[fd] = f;
    80005286:	01a50793          	addi	a5,a0,26
    8000528a:	078e                	slli	a5,a5,0x3
    8000528c:	963e                	add	a2,a2,a5
    8000528e:	e204                	sd	s1,0(a2)
      return fd;
    80005290:	b7f5                	j	8000527c <fdalloc+0x2c>

0000000080005292 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005292:	715d                	addi	sp,sp,-80
    80005294:	e486                	sd	ra,72(sp)
    80005296:	e0a2                	sd	s0,64(sp)
    80005298:	fc26                	sd	s1,56(sp)
    8000529a:	f84a                	sd	s2,48(sp)
    8000529c:	f44e                	sd	s3,40(sp)
    8000529e:	f052                	sd	s4,32(sp)
    800052a0:	ec56                	sd	s5,24(sp)
    800052a2:	e85a                	sd	s6,16(sp)
    800052a4:	0880                	addi	s0,sp,80
    800052a6:	8b2e                	mv	s6,a1
    800052a8:	89b2                	mv	s3,a2
    800052aa:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052ac:	fb040593          	addi	a1,s0,-80
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	e4e080e7          	jalr	-434(ra) # 800040fe <nameiparent>
    800052b8:	84aa                	mv	s1,a0
    800052ba:	16050063          	beqz	a0,8000541a <create+0x188>
    return 0;

  ilock(dp);
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	67c080e7          	jalr	1660(ra) # 8000393a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052c6:	4601                	li	a2,0
    800052c8:	fb040593          	addi	a1,s0,-80
    800052cc:	8526                	mv	a0,s1
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	b50080e7          	jalr	-1200(ra) # 80003e1e <dirlookup>
    800052d6:	8aaa                	mv	s5,a0
    800052d8:	c931                	beqz	a0,8000532c <create+0x9a>
    iunlockput(dp);
    800052da:	8526                	mv	a0,s1
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	8c0080e7          	jalr	-1856(ra) # 80003b9c <iunlockput>
    ilock(ip);
    800052e4:	8556                	mv	a0,s5
    800052e6:	ffffe097          	auipc	ra,0xffffe
    800052ea:	654080e7          	jalr	1620(ra) # 8000393a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052ee:	000b059b          	sext.w	a1,s6
    800052f2:	4789                	li	a5,2
    800052f4:	02f59563          	bne	a1,a5,8000531e <create+0x8c>
    800052f8:	044ad783          	lhu	a5,68(s5)
    800052fc:	37f9                	addiw	a5,a5,-2
    800052fe:	17c2                	slli	a5,a5,0x30
    80005300:	93c1                	srli	a5,a5,0x30
    80005302:	4705                	li	a4,1
    80005304:	00f76d63          	bltu	a4,a5,8000531e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005308:	8556                	mv	a0,s5
    8000530a:	60a6                	ld	ra,72(sp)
    8000530c:	6406                	ld	s0,64(sp)
    8000530e:	74e2                	ld	s1,56(sp)
    80005310:	7942                	ld	s2,48(sp)
    80005312:	79a2                	ld	s3,40(sp)
    80005314:	7a02                	ld	s4,32(sp)
    80005316:	6ae2                	ld	s5,24(sp)
    80005318:	6b42                	ld	s6,16(sp)
    8000531a:	6161                	addi	sp,sp,80
    8000531c:	8082                	ret
    iunlockput(ip);
    8000531e:	8556                	mv	a0,s5
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	87c080e7          	jalr	-1924(ra) # 80003b9c <iunlockput>
    return 0;
    80005328:	4a81                	li	s5,0
    8000532a:	bff9                	j	80005308 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000532c:	85da                	mv	a1,s6
    8000532e:	4088                	lw	a0,0(s1)
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	46e080e7          	jalr	1134(ra) # 8000379e <ialloc>
    80005338:	8a2a                	mv	s4,a0
    8000533a:	c921                	beqz	a0,8000538a <create+0xf8>
  ilock(ip);
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	5fe080e7          	jalr	1534(ra) # 8000393a <ilock>
  ip->major = major;
    80005344:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005348:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000534c:	4785                	li	a5,1
    8000534e:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005352:	8552                	mv	a0,s4
    80005354:	ffffe097          	auipc	ra,0xffffe
    80005358:	51c080e7          	jalr	1308(ra) # 80003870 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000535c:	000b059b          	sext.w	a1,s6
    80005360:	4785                	li	a5,1
    80005362:	02f58b63          	beq	a1,a5,80005398 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005366:	004a2603          	lw	a2,4(s4)
    8000536a:	fb040593          	addi	a1,s0,-80
    8000536e:	8526                	mv	a0,s1
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	cbe080e7          	jalr	-834(ra) # 8000402e <dirlink>
    80005378:	06054f63          	bltz	a0,800053f6 <create+0x164>
  iunlockput(dp);
    8000537c:	8526                	mv	a0,s1
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	81e080e7          	jalr	-2018(ra) # 80003b9c <iunlockput>
  return ip;
    80005386:	8ad2                	mv	s5,s4
    80005388:	b741                	j	80005308 <create+0x76>
    iunlockput(dp);
    8000538a:	8526                	mv	a0,s1
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	810080e7          	jalr	-2032(ra) # 80003b9c <iunlockput>
    return 0;
    80005394:	8ad2                	mv	s5,s4
    80005396:	bf8d                	j	80005308 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005398:	004a2603          	lw	a2,4(s4)
    8000539c:	00003597          	auipc	a1,0x3
    800053a0:	4f458593          	addi	a1,a1,1268 # 80008890 <syscalls+0x2b0>
    800053a4:	8552                	mv	a0,s4
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	c88080e7          	jalr	-888(ra) # 8000402e <dirlink>
    800053ae:	04054463          	bltz	a0,800053f6 <create+0x164>
    800053b2:	40d0                	lw	a2,4(s1)
    800053b4:	00003597          	auipc	a1,0x3
    800053b8:	4e458593          	addi	a1,a1,1252 # 80008898 <syscalls+0x2b8>
    800053bc:	8552                	mv	a0,s4
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	c70080e7          	jalr	-912(ra) # 8000402e <dirlink>
    800053c6:	02054863          	bltz	a0,800053f6 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800053ca:	004a2603          	lw	a2,4(s4)
    800053ce:	fb040593          	addi	a1,s0,-80
    800053d2:	8526                	mv	a0,s1
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	c5a080e7          	jalr	-934(ra) # 8000402e <dirlink>
    800053dc:	00054d63          	bltz	a0,800053f6 <create+0x164>
    dp->nlink++;  // for ".."
    800053e0:	04a4d783          	lhu	a5,74(s1)
    800053e4:	2785                	addiw	a5,a5,1
    800053e6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053ea:	8526                	mv	a0,s1
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	484080e7          	jalr	1156(ra) # 80003870 <iupdate>
    800053f4:	b761                	j	8000537c <create+0xea>
  ip->nlink = 0;
    800053f6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053fa:	8552                	mv	a0,s4
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	474080e7          	jalr	1140(ra) # 80003870 <iupdate>
  iunlockput(ip);
    80005404:	8552                	mv	a0,s4
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	796080e7          	jalr	1942(ra) # 80003b9c <iunlockput>
  iunlockput(dp);
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	78c080e7          	jalr	1932(ra) # 80003b9c <iunlockput>
  return 0;
    80005418:	bdc5                	j	80005308 <create+0x76>
    return 0;
    8000541a:	8aaa                	mv	s5,a0
    8000541c:	b5f5                	j	80005308 <create+0x76>

000000008000541e <sys_dup>:
{
    8000541e:	7179                	addi	sp,sp,-48
    80005420:	f406                	sd	ra,40(sp)
    80005422:	f022                	sd	s0,32(sp)
    80005424:	ec26                	sd	s1,24(sp)
    80005426:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005428:	fd840613          	addi	a2,s0,-40
    8000542c:	4581                	li	a1,0
    8000542e:	4501                	li	a0,0
    80005430:	00000097          	auipc	ra,0x0
    80005434:	dc0080e7          	jalr	-576(ra) # 800051f0 <argfd>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000543a:	02054363          	bltz	a0,80005460 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000543e:	fd843503          	ld	a0,-40(s0)
    80005442:	00000097          	auipc	ra,0x0
    80005446:	e0e080e7          	jalr	-498(ra) # 80005250 <fdalloc>
    8000544a:	84aa                	mv	s1,a0
    return -1;
    8000544c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000544e:	00054963          	bltz	a0,80005460 <sys_dup+0x42>
  filedup(f);
    80005452:	fd843503          	ld	a0,-40(s0)
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	320080e7          	jalr	800(ra) # 80004776 <filedup>
  return fd;
    8000545e:	87a6                	mv	a5,s1
}
    80005460:	853e                	mv	a0,a5
    80005462:	70a2                	ld	ra,40(sp)
    80005464:	7402                	ld	s0,32(sp)
    80005466:	64e2                	ld	s1,24(sp)
    80005468:	6145                	addi	sp,sp,48
    8000546a:	8082                	ret

000000008000546c <sys_read>:
{
    8000546c:	7179                	addi	sp,sp,-48
    8000546e:	f406                	sd	ra,40(sp)
    80005470:	f022                	sd	s0,32(sp)
    80005472:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005474:	fd840593          	addi	a1,s0,-40
    80005478:	4505                	li	a0,1
    8000547a:	ffffd097          	auipc	ra,0xffffd
    8000547e:	714080e7          	jalr	1812(ra) # 80002b8e <argaddr>
  argint(2, &n);
    80005482:	fe440593          	addi	a1,s0,-28
    80005486:	4509                	li	a0,2
    80005488:	ffffd097          	auipc	ra,0xffffd
    8000548c:	6e6080e7          	jalr	1766(ra) # 80002b6e <argint>
  if(argfd(0, 0, &f) < 0)
    80005490:	fe840613          	addi	a2,s0,-24
    80005494:	4581                	li	a1,0
    80005496:	4501                	li	a0,0
    80005498:	00000097          	auipc	ra,0x0
    8000549c:	d58080e7          	jalr	-680(ra) # 800051f0 <argfd>
    800054a0:	87aa                	mv	a5,a0
    return -1;
    800054a2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054a4:	0007cc63          	bltz	a5,800054bc <sys_read+0x50>
  return fileread(f, p, n);
    800054a8:	fe442603          	lw	a2,-28(s0)
    800054ac:	fd843583          	ld	a1,-40(s0)
    800054b0:	fe843503          	ld	a0,-24(s0)
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	44e080e7          	jalr	1102(ra) # 80004902 <fileread>
}
    800054bc:	70a2                	ld	ra,40(sp)
    800054be:	7402                	ld	s0,32(sp)
    800054c0:	6145                	addi	sp,sp,48
    800054c2:	8082                	ret

00000000800054c4 <sys_write>:
{
    800054c4:	7179                	addi	sp,sp,-48
    800054c6:	f406                	sd	ra,40(sp)
    800054c8:	f022                	sd	s0,32(sp)
    800054ca:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054cc:	fd840593          	addi	a1,s0,-40
    800054d0:	4505                	li	a0,1
    800054d2:	ffffd097          	auipc	ra,0xffffd
    800054d6:	6bc080e7          	jalr	1724(ra) # 80002b8e <argaddr>
  argint(2, &n);
    800054da:	fe440593          	addi	a1,s0,-28
    800054de:	4509                	li	a0,2
    800054e0:	ffffd097          	auipc	ra,0xffffd
    800054e4:	68e080e7          	jalr	1678(ra) # 80002b6e <argint>
  if(argfd(0, 0, &f) < 0)
    800054e8:	fe840613          	addi	a2,s0,-24
    800054ec:	4581                	li	a1,0
    800054ee:	4501                	li	a0,0
    800054f0:	00000097          	auipc	ra,0x0
    800054f4:	d00080e7          	jalr	-768(ra) # 800051f0 <argfd>
    800054f8:	87aa                	mv	a5,a0
    return -1;
    800054fa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054fc:	0007cc63          	bltz	a5,80005514 <sys_write+0x50>
  return filewrite(f, p, n);
    80005500:	fe442603          	lw	a2,-28(s0)
    80005504:	fd843583          	ld	a1,-40(s0)
    80005508:	fe843503          	ld	a0,-24(s0)
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	4b8080e7          	jalr	1208(ra) # 800049c4 <filewrite>
}
    80005514:	70a2                	ld	ra,40(sp)
    80005516:	7402                	ld	s0,32(sp)
    80005518:	6145                	addi	sp,sp,48
    8000551a:	8082                	ret

000000008000551c <sys_close>:
{
    8000551c:	1101                	addi	sp,sp,-32
    8000551e:	ec06                	sd	ra,24(sp)
    80005520:	e822                	sd	s0,16(sp)
    80005522:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005524:	fe040613          	addi	a2,s0,-32
    80005528:	fec40593          	addi	a1,s0,-20
    8000552c:	4501                	li	a0,0
    8000552e:	00000097          	auipc	ra,0x0
    80005532:	cc2080e7          	jalr	-830(ra) # 800051f0 <argfd>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005538:	02054463          	bltz	a0,80005560 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000553c:	ffffc097          	auipc	ra,0xffffc
    80005540:	48a080e7          	jalr	1162(ra) # 800019c6 <myproc>
    80005544:	fec42783          	lw	a5,-20(s0)
    80005548:	07e9                	addi	a5,a5,26
    8000554a:	078e                	slli	a5,a5,0x3
    8000554c:	97aa                	add	a5,a5,a0
    8000554e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005552:	fe043503          	ld	a0,-32(s0)
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	272080e7          	jalr	626(ra) # 800047c8 <fileclose>
  return 0;
    8000555e:	4781                	li	a5,0
}
    80005560:	853e                	mv	a0,a5
    80005562:	60e2                	ld	ra,24(sp)
    80005564:	6442                	ld	s0,16(sp)
    80005566:	6105                	addi	sp,sp,32
    80005568:	8082                	ret

000000008000556a <sys_fstat>:
{
    8000556a:	1101                	addi	sp,sp,-32
    8000556c:	ec06                	sd	ra,24(sp)
    8000556e:	e822                	sd	s0,16(sp)
    80005570:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005572:	fe040593          	addi	a1,s0,-32
    80005576:	4505                	li	a0,1
    80005578:	ffffd097          	auipc	ra,0xffffd
    8000557c:	616080e7          	jalr	1558(ra) # 80002b8e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005580:	fe840613          	addi	a2,s0,-24
    80005584:	4581                	li	a1,0
    80005586:	4501                	li	a0,0
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	c68080e7          	jalr	-920(ra) # 800051f0 <argfd>
    80005590:	87aa                	mv	a5,a0
    return -1;
    80005592:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005594:	0007ca63          	bltz	a5,800055a8 <sys_fstat+0x3e>
  return filestat(f, st);
    80005598:	fe043583          	ld	a1,-32(s0)
    8000559c:	fe843503          	ld	a0,-24(s0)
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	2f0080e7          	jalr	752(ra) # 80004890 <filestat>
}
    800055a8:	60e2                	ld	ra,24(sp)
    800055aa:	6442                	ld	s0,16(sp)
    800055ac:	6105                	addi	sp,sp,32
    800055ae:	8082                	ret

00000000800055b0 <sys_link>:
{
    800055b0:	7169                	addi	sp,sp,-304
    800055b2:	f606                	sd	ra,296(sp)
    800055b4:	f222                	sd	s0,288(sp)
    800055b6:	ee26                	sd	s1,280(sp)
    800055b8:	ea4a                	sd	s2,272(sp)
    800055ba:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055bc:	08000613          	li	a2,128
    800055c0:	ed040593          	addi	a1,s0,-304
    800055c4:	4501                	li	a0,0
    800055c6:	ffffd097          	auipc	ra,0xffffd
    800055ca:	5e8080e7          	jalr	1512(ra) # 80002bae <argstr>
    return -1;
    800055ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d0:	10054e63          	bltz	a0,800056ec <sys_link+0x13c>
    800055d4:	08000613          	li	a2,128
    800055d8:	f5040593          	addi	a1,s0,-176
    800055dc:	4505                	li	a0,1
    800055de:	ffffd097          	auipc	ra,0xffffd
    800055e2:	5d0080e7          	jalr	1488(ra) # 80002bae <argstr>
    return -1;
    800055e6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055e8:	10054263          	bltz	a0,800056ec <sys_link+0x13c>
  begin_op();
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	d10080e7          	jalr	-752(ra) # 800042fc <begin_op>
  if((ip = namei(old)) == 0){
    800055f4:	ed040513          	addi	a0,s0,-304
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	ae8080e7          	jalr	-1304(ra) # 800040e0 <namei>
    80005600:	84aa                	mv	s1,a0
    80005602:	c551                	beqz	a0,8000568e <sys_link+0xde>
  ilock(ip);
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	336080e7          	jalr	822(ra) # 8000393a <ilock>
  if(ip->type == T_DIR){
    8000560c:	04449703          	lh	a4,68(s1)
    80005610:	4785                	li	a5,1
    80005612:	08f70463          	beq	a4,a5,8000569a <sys_link+0xea>
  ip->nlink++;
    80005616:	04a4d783          	lhu	a5,74(s1)
    8000561a:	2785                	addiw	a5,a5,1
    8000561c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	24e080e7          	jalr	590(ra) # 80003870 <iupdate>
  iunlock(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	3d0080e7          	jalr	976(ra) # 800039fc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005634:	fd040593          	addi	a1,s0,-48
    80005638:	f5040513          	addi	a0,s0,-176
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	ac2080e7          	jalr	-1342(ra) # 800040fe <nameiparent>
    80005644:	892a                	mv	s2,a0
    80005646:	c935                	beqz	a0,800056ba <sys_link+0x10a>
  ilock(dp);
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	2f2080e7          	jalr	754(ra) # 8000393a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005650:	00092703          	lw	a4,0(s2)
    80005654:	409c                	lw	a5,0(s1)
    80005656:	04f71d63          	bne	a4,a5,800056b0 <sys_link+0x100>
    8000565a:	40d0                	lw	a2,4(s1)
    8000565c:	fd040593          	addi	a1,s0,-48
    80005660:	854a                	mv	a0,s2
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	9cc080e7          	jalr	-1588(ra) # 8000402e <dirlink>
    8000566a:	04054363          	bltz	a0,800056b0 <sys_link+0x100>
  iunlockput(dp);
    8000566e:	854a                	mv	a0,s2
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	52c080e7          	jalr	1324(ra) # 80003b9c <iunlockput>
  iput(ip);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	47a080e7          	jalr	1146(ra) # 80003af4 <iput>
  end_op();
    80005682:	fffff097          	auipc	ra,0xfffff
    80005686:	cfa080e7          	jalr	-774(ra) # 8000437c <end_op>
  return 0;
    8000568a:	4781                	li	a5,0
    8000568c:	a085                	j	800056ec <sys_link+0x13c>
    end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	cee080e7          	jalr	-786(ra) # 8000437c <end_op>
    return -1;
    80005696:	57fd                	li	a5,-1
    80005698:	a891                	j	800056ec <sys_link+0x13c>
    iunlockput(ip);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	500080e7          	jalr	1280(ra) # 80003b9c <iunlockput>
    end_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	cd8080e7          	jalr	-808(ra) # 8000437c <end_op>
    return -1;
    800056ac:	57fd                	li	a5,-1
    800056ae:	a83d                	j	800056ec <sys_link+0x13c>
    iunlockput(dp);
    800056b0:	854a                	mv	a0,s2
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	4ea080e7          	jalr	1258(ra) # 80003b9c <iunlockput>
  ilock(ip);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	27e080e7          	jalr	638(ra) # 8000393a <ilock>
  ip->nlink--;
    800056c4:	04a4d783          	lhu	a5,74(s1)
    800056c8:	37fd                	addiw	a5,a5,-1
    800056ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ce:	8526                	mv	a0,s1
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	1a0080e7          	jalr	416(ra) # 80003870 <iupdate>
  iunlockput(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	4c2080e7          	jalr	1218(ra) # 80003b9c <iunlockput>
  end_op();
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	c9a080e7          	jalr	-870(ra) # 8000437c <end_op>
  return -1;
    800056ea:	57fd                	li	a5,-1
}
    800056ec:	853e                	mv	a0,a5
    800056ee:	70b2                	ld	ra,296(sp)
    800056f0:	7412                	ld	s0,288(sp)
    800056f2:	64f2                	ld	s1,280(sp)
    800056f4:	6952                	ld	s2,272(sp)
    800056f6:	6155                	addi	sp,sp,304
    800056f8:	8082                	ret

00000000800056fa <sys_unlink>:
{
    800056fa:	7151                	addi	sp,sp,-240
    800056fc:	f586                	sd	ra,232(sp)
    800056fe:	f1a2                	sd	s0,224(sp)
    80005700:	eda6                	sd	s1,216(sp)
    80005702:	e9ca                	sd	s2,208(sp)
    80005704:	e5ce                	sd	s3,200(sp)
    80005706:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005708:	08000613          	li	a2,128
    8000570c:	f3040593          	addi	a1,s0,-208
    80005710:	4501                	li	a0,0
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	49c080e7          	jalr	1180(ra) # 80002bae <argstr>
    8000571a:	18054163          	bltz	a0,8000589c <sys_unlink+0x1a2>
  begin_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	bde080e7          	jalr	-1058(ra) # 800042fc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005726:	fb040593          	addi	a1,s0,-80
    8000572a:	f3040513          	addi	a0,s0,-208
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	9d0080e7          	jalr	-1584(ra) # 800040fe <nameiparent>
    80005736:	84aa                	mv	s1,a0
    80005738:	c979                	beqz	a0,8000580e <sys_unlink+0x114>
  ilock(dp);
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	200080e7          	jalr	512(ra) # 8000393a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005742:	00003597          	auipc	a1,0x3
    80005746:	14e58593          	addi	a1,a1,334 # 80008890 <syscalls+0x2b0>
    8000574a:	fb040513          	addi	a0,s0,-80
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	6b6080e7          	jalr	1718(ra) # 80003e04 <namecmp>
    80005756:	14050a63          	beqz	a0,800058aa <sys_unlink+0x1b0>
    8000575a:	00003597          	auipc	a1,0x3
    8000575e:	13e58593          	addi	a1,a1,318 # 80008898 <syscalls+0x2b8>
    80005762:	fb040513          	addi	a0,s0,-80
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	69e080e7          	jalr	1694(ra) # 80003e04 <namecmp>
    8000576e:	12050e63          	beqz	a0,800058aa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005772:	f2c40613          	addi	a2,s0,-212
    80005776:	fb040593          	addi	a1,s0,-80
    8000577a:	8526                	mv	a0,s1
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	6a2080e7          	jalr	1698(ra) # 80003e1e <dirlookup>
    80005784:	892a                	mv	s2,a0
    80005786:	12050263          	beqz	a0,800058aa <sys_unlink+0x1b0>
  ilock(ip);
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	1b0080e7          	jalr	432(ra) # 8000393a <ilock>
  if(ip->nlink < 1)
    80005792:	04a91783          	lh	a5,74(s2)
    80005796:	08f05263          	blez	a5,8000581a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000579a:	04491703          	lh	a4,68(s2)
    8000579e:	4785                	li	a5,1
    800057a0:	08f70563          	beq	a4,a5,8000582a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057a4:	4641                	li	a2,16
    800057a6:	4581                	li	a1,0
    800057a8:	fc040513          	addi	a0,s0,-64
    800057ac:	ffffb097          	auipc	ra,0xffffb
    800057b0:	53a080e7          	jalr	1338(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b4:	4741                	li	a4,16
    800057b6:	f2c42683          	lw	a3,-212(s0)
    800057ba:	fc040613          	addi	a2,s0,-64
    800057be:	4581                	li	a1,0
    800057c0:	8526                	mv	a0,s1
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	524080e7          	jalr	1316(ra) # 80003ce6 <writei>
    800057ca:	47c1                	li	a5,16
    800057cc:	0af51563          	bne	a0,a5,80005876 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057d0:	04491703          	lh	a4,68(s2)
    800057d4:	4785                	li	a5,1
    800057d6:	0af70863          	beq	a4,a5,80005886 <sys_unlink+0x18c>
  iunlockput(dp);
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	3c0080e7          	jalr	960(ra) # 80003b9c <iunlockput>
  ip->nlink--;
    800057e4:	04a95783          	lhu	a5,74(s2)
    800057e8:	37fd                	addiw	a5,a5,-1
    800057ea:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057ee:	854a                	mv	a0,s2
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	080080e7          	jalr	128(ra) # 80003870 <iupdate>
  iunlockput(ip);
    800057f8:	854a                	mv	a0,s2
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	3a2080e7          	jalr	930(ra) # 80003b9c <iunlockput>
  end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	b7a080e7          	jalr	-1158(ra) # 8000437c <end_op>
  return 0;
    8000580a:	4501                	li	a0,0
    8000580c:	a84d                	j	800058be <sys_unlink+0x1c4>
    end_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	b6e080e7          	jalr	-1170(ra) # 8000437c <end_op>
    return -1;
    80005816:	557d                	li	a0,-1
    80005818:	a05d                	j	800058be <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000581a:	00003517          	auipc	a0,0x3
    8000581e:	08650513          	addi	a0,a0,134 # 800088a0 <syscalls+0x2c0>
    80005822:	ffffb097          	auipc	ra,0xffffb
    80005826:	d22080e7          	jalr	-734(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000582a:	04c92703          	lw	a4,76(s2)
    8000582e:	02000793          	li	a5,32
    80005832:	f6e7f9e3          	bgeu	a5,a4,800057a4 <sys_unlink+0xaa>
    80005836:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000583a:	4741                	li	a4,16
    8000583c:	86ce                	mv	a3,s3
    8000583e:	f1840613          	addi	a2,s0,-232
    80005842:	4581                	li	a1,0
    80005844:	854a                	mv	a0,s2
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	3a8080e7          	jalr	936(ra) # 80003bee <readi>
    8000584e:	47c1                	li	a5,16
    80005850:	00f51b63          	bne	a0,a5,80005866 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005854:	f1845783          	lhu	a5,-232(s0)
    80005858:	e7a1                	bnez	a5,800058a0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000585a:	29c1                	addiw	s3,s3,16
    8000585c:	04c92783          	lw	a5,76(s2)
    80005860:	fcf9ede3          	bltu	s3,a5,8000583a <sys_unlink+0x140>
    80005864:	b781                	j	800057a4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005866:	00003517          	auipc	a0,0x3
    8000586a:	05250513          	addi	a0,a0,82 # 800088b8 <syscalls+0x2d8>
    8000586e:	ffffb097          	auipc	ra,0xffffb
    80005872:	cd6080e7          	jalr	-810(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005876:	00003517          	auipc	a0,0x3
    8000587a:	05a50513          	addi	a0,a0,90 # 800088d0 <syscalls+0x2f0>
    8000587e:	ffffb097          	auipc	ra,0xffffb
    80005882:	cc6080e7          	jalr	-826(ra) # 80000544 <panic>
    dp->nlink--;
    80005886:	04a4d783          	lhu	a5,74(s1)
    8000588a:	37fd                	addiw	a5,a5,-1
    8000588c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005890:	8526                	mv	a0,s1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	fde080e7          	jalr	-34(ra) # 80003870 <iupdate>
    8000589a:	b781                	j	800057da <sys_unlink+0xe0>
    return -1;
    8000589c:	557d                	li	a0,-1
    8000589e:	a005                	j	800058be <sys_unlink+0x1c4>
    iunlockput(ip);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	2fa080e7          	jalr	762(ra) # 80003b9c <iunlockput>
  iunlockput(dp);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	2f0080e7          	jalr	752(ra) # 80003b9c <iunlockput>
  end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	ac8080e7          	jalr	-1336(ra) # 8000437c <end_op>
  return -1;
    800058bc:	557d                	li	a0,-1
}
    800058be:	70ae                	ld	ra,232(sp)
    800058c0:	740e                	ld	s0,224(sp)
    800058c2:	64ee                	ld	s1,216(sp)
    800058c4:	694e                	ld	s2,208(sp)
    800058c6:	69ae                	ld	s3,200(sp)
    800058c8:	616d                	addi	sp,sp,240
    800058ca:	8082                	ret

00000000800058cc <sys_open>:

uint64
sys_open(void)
{
    800058cc:	7131                	addi	sp,sp,-192
    800058ce:	fd06                	sd	ra,184(sp)
    800058d0:	f922                	sd	s0,176(sp)
    800058d2:	f526                	sd	s1,168(sp)
    800058d4:	f14a                	sd	s2,160(sp)
    800058d6:	ed4e                	sd	s3,152(sp)
    800058d8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058da:	f4c40593          	addi	a1,s0,-180
    800058de:	4505                	li	a0,1
    800058e0:	ffffd097          	auipc	ra,0xffffd
    800058e4:	28e080e7          	jalr	654(ra) # 80002b6e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058e8:	08000613          	li	a2,128
    800058ec:	f5040593          	addi	a1,s0,-176
    800058f0:	4501                	li	a0,0
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	2bc080e7          	jalr	700(ra) # 80002bae <argstr>
    800058fa:	87aa                	mv	a5,a0
    return -1;
    800058fc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058fe:	0a07c963          	bltz	a5,800059b0 <sys_open+0xe4>

  begin_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	9fa080e7          	jalr	-1542(ra) # 800042fc <begin_op>

  if(omode & O_CREATE){
    8000590a:	f4c42783          	lw	a5,-180(s0)
    8000590e:	2007f793          	andi	a5,a5,512
    80005912:	cfc5                	beqz	a5,800059ca <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005914:	4681                	li	a3,0
    80005916:	4601                	li	a2,0
    80005918:	4589                	li	a1,2
    8000591a:	f5040513          	addi	a0,s0,-176
    8000591e:	00000097          	auipc	ra,0x0
    80005922:	974080e7          	jalr	-1676(ra) # 80005292 <create>
    80005926:	84aa                	mv	s1,a0
    if(ip == 0){
    80005928:	c959                	beqz	a0,800059be <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000592a:	04449703          	lh	a4,68(s1)
    8000592e:	478d                	li	a5,3
    80005930:	00f71763          	bne	a4,a5,8000593e <sys_open+0x72>
    80005934:	0464d703          	lhu	a4,70(s1)
    80005938:	47a5                	li	a5,9
    8000593a:	0ce7ed63          	bltu	a5,a4,80005a14 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	dce080e7          	jalr	-562(ra) # 8000470c <filealloc>
    80005946:	89aa                	mv	s3,a0
    80005948:	10050363          	beqz	a0,80005a4e <sys_open+0x182>
    8000594c:	00000097          	auipc	ra,0x0
    80005950:	904080e7          	jalr	-1788(ra) # 80005250 <fdalloc>
    80005954:	892a                	mv	s2,a0
    80005956:	0e054763          	bltz	a0,80005a44 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000595a:	04449703          	lh	a4,68(s1)
    8000595e:	478d                	li	a5,3
    80005960:	0cf70563          	beq	a4,a5,80005a2a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005964:	4789                	li	a5,2
    80005966:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000596a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000596e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005972:	f4c42783          	lw	a5,-180(s0)
    80005976:	0017c713          	xori	a4,a5,1
    8000597a:	8b05                	andi	a4,a4,1
    8000597c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005980:	0037f713          	andi	a4,a5,3
    80005984:	00e03733          	snez	a4,a4
    80005988:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000598c:	4007f793          	andi	a5,a5,1024
    80005990:	c791                	beqz	a5,8000599c <sys_open+0xd0>
    80005992:	04449703          	lh	a4,68(s1)
    80005996:	4789                	li	a5,2
    80005998:	0af70063          	beq	a4,a5,80005a38 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	05e080e7          	jalr	94(ra) # 800039fc <iunlock>
  end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	9d6080e7          	jalr	-1578(ra) # 8000437c <end_op>

  return fd;
    800059ae:	854a                	mv	a0,s2
}
    800059b0:	70ea                	ld	ra,184(sp)
    800059b2:	744a                	ld	s0,176(sp)
    800059b4:	74aa                	ld	s1,168(sp)
    800059b6:	790a                	ld	s2,160(sp)
    800059b8:	69ea                	ld	s3,152(sp)
    800059ba:	6129                	addi	sp,sp,192
    800059bc:	8082                	ret
      end_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	9be080e7          	jalr	-1602(ra) # 8000437c <end_op>
      return -1;
    800059c6:	557d                	li	a0,-1
    800059c8:	b7e5                	j	800059b0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059ca:	f5040513          	addi	a0,s0,-176
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	712080e7          	jalr	1810(ra) # 800040e0 <namei>
    800059d6:	84aa                	mv	s1,a0
    800059d8:	c905                	beqz	a0,80005a08 <sys_open+0x13c>
    ilock(ip);
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	f60080e7          	jalr	-160(ra) # 8000393a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059e2:	04449703          	lh	a4,68(s1)
    800059e6:	4785                	li	a5,1
    800059e8:	f4f711e3          	bne	a4,a5,8000592a <sys_open+0x5e>
    800059ec:	f4c42783          	lw	a5,-180(s0)
    800059f0:	d7b9                	beqz	a5,8000593e <sys_open+0x72>
      iunlockput(ip);
    800059f2:	8526                	mv	a0,s1
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	1a8080e7          	jalr	424(ra) # 80003b9c <iunlockput>
      end_op();
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	980080e7          	jalr	-1664(ra) # 8000437c <end_op>
      return -1;
    80005a04:	557d                	li	a0,-1
    80005a06:	b76d                	j	800059b0 <sys_open+0xe4>
      end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	974080e7          	jalr	-1676(ra) # 8000437c <end_op>
      return -1;
    80005a10:	557d                	li	a0,-1
    80005a12:	bf79                	j	800059b0 <sys_open+0xe4>
    iunlockput(ip);
    80005a14:	8526                	mv	a0,s1
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	186080e7          	jalr	390(ra) # 80003b9c <iunlockput>
    end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	95e080e7          	jalr	-1698(ra) # 8000437c <end_op>
    return -1;
    80005a26:	557d                	li	a0,-1
    80005a28:	b761                	j	800059b0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a2a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a2e:	04649783          	lh	a5,70(s1)
    80005a32:	02f99223          	sh	a5,36(s3)
    80005a36:	bf25                	j	8000596e <sys_open+0xa2>
    itrunc(ip);
    80005a38:	8526                	mv	a0,s1
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	00e080e7          	jalr	14(ra) # 80003a48 <itrunc>
    80005a42:	bfa9                	j	8000599c <sys_open+0xd0>
      fileclose(f);
    80005a44:	854e                	mv	a0,s3
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	d82080e7          	jalr	-638(ra) # 800047c8 <fileclose>
    iunlockput(ip);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	14c080e7          	jalr	332(ra) # 80003b9c <iunlockput>
    end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	924080e7          	jalr	-1756(ra) # 8000437c <end_op>
    return -1;
    80005a60:	557d                	li	a0,-1
    80005a62:	b7b9                	j	800059b0 <sys_open+0xe4>

0000000080005a64 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a64:	7175                	addi	sp,sp,-144
    80005a66:	e506                	sd	ra,136(sp)
    80005a68:	e122                	sd	s0,128(sp)
    80005a6a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	890080e7          	jalr	-1904(ra) # 800042fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a74:	08000613          	li	a2,128
    80005a78:	f7040593          	addi	a1,s0,-144
    80005a7c:	4501                	li	a0,0
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	130080e7          	jalr	304(ra) # 80002bae <argstr>
    80005a86:	02054963          	bltz	a0,80005ab8 <sys_mkdir+0x54>
    80005a8a:	4681                	li	a3,0
    80005a8c:	4601                	li	a2,0
    80005a8e:	4585                	li	a1,1
    80005a90:	f7040513          	addi	a0,s0,-144
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	7fe080e7          	jalr	2046(ra) # 80005292 <create>
    80005a9c:	cd11                	beqz	a0,80005ab8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	0fe080e7          	jalr	254(ra) # 80003b9c <iunlockput>
  end_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	8d6080e7          	jalr	-1834(ra) # 8000437c <end_op>
  return 0;
    80005aae:	4501                	li	a0,0
}
    80005ab0:	60aa                	ld	ra,136(sp)
    80005ab2:	640a                	ld	s0,128(sp)
    80005ab4:	6149                	addi	sp,sp,144
    80005ab6:	8082                	ret
    end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	8c4080e7          	jalr	-1852(ra) # 8000437c <end_op>
    return -1;
    80005ac0:	557d                	li	a0,-1
    80005ac2:	b7fd                	j	80005ab0 <sys_mkdir+0x4c>

0000000080005ac4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ac4:	7135                	addi	sp,sp,-160
    80005ac6:	ed06                	sd	ra,152(sp)
    80005ac8:	e922                	sd	s0,144(sp)
    80005aca:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	830080e7          	jalr	-2000(ra) # 800042fc <begin_op>
  argint(1, &major);
    80005ad4:	f6c40593          	addi	a1,s0,-148
    80005ad8:	4505                	li	a0,1
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	094080e7          	jalr	148(ra) # 80002b6e <argint>
  argint(2, &minor);
    80005ae2:	f6840593          	addi	a1,s0,-152
    80005ae6:	4509                	li	a0,2
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	086080e7          	jalr	134(ra) # 80002b6e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005af0:	08000613          	li	a2,128
    80005af4:	f7040593          	addi	a1,s0,-144
    80005af8:	4501                	li	a0,0
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	0b4080e7          	jalr	180(ra) # 80002bae <argstr>
    80005b02:	02054b63          	bltz	a0,80005b38 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b06:	f6841683          	lh	a3,-152(s0)
    80005b0a:	f6c41603          	lh	a2,-148(s0)
    80005b0e:	458d                	li	a1,3
    80005b10:	f7040513          	addi	a0,s0,-144
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	77e080e7          	jalr	1918(ra) # 80005292 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b1c:	cd11                	beqz	a0,80005b38 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	07e080e7          	jalr	126(ra) # 80003b9c <iunlockput>
  end_op();
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	856080e7          	jalr	-1962(ra) # 8000437c <end_op>
  return 0;
    80005b2e:	4501                	li	a0,0
}
    80005b30:	60ea                	ld	ra,152(sp)
    80005b32:	644a                	ld	s0,144(sp)
    80005b34:	610d                	addi	sp,sp,160
    80005b36:	8082                	ret
    end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	844080e7          	jalr	-1980(ra) # 8000437c <end_op>
    return -1;
    80005b40:	557d                	li	a0,-1
    80005b42:	b7fd                	j	80005b30 <sys_mknod+0x6c>

0000000080005b44 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b44:	7135                	addi	sp,sp,-160
    80005b46:	ed06                	sd	ra,152(sp)
    80005b48:	e922                	sd	s0,144(sp)
    80005b4a:	e526                	sd	s1,136(sp)
    80005b4c:	e14a                	sd	s2,128(sp)
    80005b4e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b50:	ffffc097          	auipc	ra,0xffffc
    80005b54:	e76080e7          	jalr	-394(ra) # 800019c6 <myproc>
    80005b58:	892a                	mv	s2,a0
  
  begin_op();
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	7a2080e7          	jalr	1954(ra) # 800042fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b62:	08000613          	li	a2,128
    80005b66:	f6040593          	addi	a1,s0,-160
    80005b6a:	4501                	li	a0,0
    80005b6c:	ffffd097          	auipc	ra,0xffffd
    80005b70:	042080e7          	jalr	66(ra) # 80002bae <argstr>
    80005b74:	04054b63          	bltz	a0,80005bca <sys_chdir+0x86>
    80005b78:	f6040513          	addi	a0,s0,-160
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	564080e7          	jalr	1380(ra) # 800040e0 <namei>
    80005b84:	84aa                	mv	s1,a0
    80005b86:	c131                	beqz	a0,80005bca <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	db2080e7          	jalr	-590(ra) # 8000393a <ilock>
  if(ip->type != T_DIR){
    80005b90:	04449703          	lh	a4,68(s1)
    80005b94:	4785                	li	a5,1
    80005b96:	04f71063          	bne	a4,a5,80005bd6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b9a:	8526                	mv	a0,s1
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	e60080e7          	jalr	-416(ra) # 800039fc <iunlock>
  iput(p->cwd);
    80005ba4:	15093503          	ld	a0,336(s2)
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	f4c080e7          	jalr	-180(ra) # 80003af4 <iput>
  end_op();
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	7cc080e7          	jalr	1996(ra) # 8000437c <end_op>
  p->cwd = ip;
    80005bb8:	14993823          	sd	s1,336(s2)
  return 0;
    80005bbc:	4501                	li	a0,0
}
    80005bbe:	60ea                	ld	ra,152(sp)
    80005bc0:	644a                	ld	s0,144(sp)
    80005bc2:	64aa                	ld	s1,136(sp)
    80005bc4:	690a                	ld	s2,128(sp)
    80005bc6:	610d                	addi	sp,sp,160
    80005bc8:	8082                	ret
    end_op();
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	7b2080e7          	jalr	1970(ra) # 8000437c <end_op>
    return -1;
    80005bd2:	557d                	li	a0,-1
    80005bd4:	b7ed                	j	80005bbe <sys_chdir+0x7a>
    iunlockput(ip);
    80005bd6:	8526                	mv	a0,s1
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	fc4080e7          	jalr	-60(ra) # 80003b9c <iunlockput>
    end_op();
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	79c080e7          	jalr	1948(ra) # 8000437c <end_op>
    return -1;
    80005be8:	557d                	li	a0,-1
    80005bea:	bfd1                	j	80005bbe <sys_chdir+0x7a>

0000000080005bec <sys_exec>:

uint64
sys_exec(void)
{
    80005bec:	7145                	addi	sp,sp,-464
    80005bee:	e786                	sd	ra,456(sp)
    80005bf0:	e3a2                	sd	s0,448(sp)
    80005bf2:	ff26                	sd	s1,440(sp)
    80005bf4:	fb4a                	sd	s2,432(sp)
    80005bf6:	f74e                	sd	s3,424(sp)
    80005bf8:	f352                	sd	s4,416(sp)
    80005bfa:	ef56                	sd	s5,408(sp)
    80005bfc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005bfe:	e3840593          	addi	a1,s0,-456
    80005c02:	4505                	li	a0,1
    80005c04:	ffffd097          	auipc	ra,0xffffd
    80005c08:	f8a080e7          	jalr	-118(ra) # 80002b8e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c0c:	08000613          	li	a2,128
    80005c10:	f4040593          	addi	a1,s0,-192
    80005c14:	4501                	li	a0,0
    80005c16:	ffffd097          	auipc	ra,0xffffd
    80005c1a:	f98080e7          	jalr	-104(ra) # 80002bae <argstr>
    80005c1e:	87aa                	mv	a5,a0
    return -1;
    80005c20:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c22:	0c07c263          	bltz	a5,80005ce6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c26:	10000613          	li	a2,256
    80005c2a:	4581                	li	a1,0
    80005c2c:	e4040513          	addi	a0,s0,-448
    80005c30:	ffffb097          	auipc	ra,0xffffb
    80005c34:	0b6080e7          	jalr	182(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c38:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c3c:	89a6                	mv	s3,s1
    80005c3e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c40:	02000a13          	li	s4,32
    80005c44:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c48:	00391513          	slli	a0,s2,0x3
    80005c4c:	e3040593          	addi	a1,s0,-464
    80005c50:	e3843783          	ld	a5,-456(s0)
    80005c54:	953e                	add	a0,a0,a5
    80005c56:	ffffd097          	auipc	ra,0xffffd
    80005c5a:	e7a080e7          	jalr	-390(ra) # 80002ad0 <fetchaddr>
    80005c5e:	02054a63          	bltz	a0,80005c92 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c62:	e3043783          	ld	a5,-464(s0)
    80005c66:	c3b9                	beqz	a5,80005cac <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c68:	ffffb097          	auipc	ra,0xffffb
    80005c6c:	e92080e7          	jalr	-366(ra) # 80000afa <kalloc>
    80005c70:	85aa                	mv	a1,a0
    80005c72:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c76:	cd11                	beqz	a0,80005c92 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c78:	6605                	lui	a2,0x1
    80005c7a:	e3043503          	ld	a0,-464(s0)
    80005c7e:	ffffd097          	auipc	ra,0xffffd
    80005c82:	ea4080e7          	jalr	-348(ra) # 80002b22 <fetchstr>
    80005c86:	00054663          	bltz	a0,80005c92 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c8a:	0905                	addi	s2,s2,1
    80005c8c:	09a1                	addi	s3,s3,8
    80005c8e:	fb491be3          	bne	s2,s4,80005c44 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c92:	10048913          	addi	s2,s1,256
    80005c96:	6088                	ld	a0,0(s1)
    80005c98:	c531                	beqz	a0,80005ce4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c9a:	ffffb097          	auipc	ra,0xffffb
    80005c9e:	d64080e7          	jalr	-668(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca2:	04a1                	addi	s1,s1,8
    80005ca4:	ff2499e3          	bne	s1,s2,80005c96 <sys_exec+0xaa>
  return -1;
    80005ca8:	557d                	li	a0,-1
    80005caa:	a835                	j	80005ce6 <sys_exec+0xfa>
      argv[i] = 0;
    80005cac:	0a8e                	slli	s5,s5,0x3
    80005cae:	fc040793          	addi	a5,s0,-64
    80005cb2:	9abe                	add	s5,s5,a5
    80005cb4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cb8:	e4040593          	addi	a1,s0,-448
    80005cbc:	f4040513          	addi	a0,s0,-192
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	190080e7          	jalr	400(ra) # 80004e50 <exec>
    80005cc8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cca:	10048993          	addi	s3,s1,256
    80005cce:	6088                	ld	a0,0(s1)
    80005cd0:	c901                	beqz	a0,80005ce0 <sys_exec+0xf4>
    kfree(argv[i]);
    80005cd2:	ffffb097          	auipc	ra,0xffffb
    80005cd6:	d2c080e7          	jalr	-724(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cda:	04a1                	addi	s1,s1,8
    80005cdc:	ff3499e3          	bne	s1,s3,80005cce <sys_exec+0xe2>
  return ret;
    80005ce0:	854a                	mv	a0,s2
    80005ce2:	a011                	j	80005ce6 <sys_exec+0xfa>
  return -1;
    80005ce4:	557d                	li	a0,-1
}
    80005ce6:	60be                	ld	ra,456(sp)
    80005ce8:	641e                	ld	s0,448(sp)
    80005cea:	74fa                	ld	s1,440(sp)
    80005cec:	795a                	ld	s2,432(sp)
    80005cee:	79ba                	ld	s3,424(sp)
    80005cf0:	7a1a                	ld	s4,416(sp)
    80005cf2:	6afa                	ld	s5,408(sp)
    80005cf4:	6179                	addi	sp,sp,464
    80005cf6:	8082                	ret

0000000080005cf8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cf8:	7139                	addi	sp,sp,-64
    80005cfa:	fc06                	sd	ra,56(sp)
    80005cfc:	f822                	sd	s0,48(sp)
    80005cfe:	f426                	sd	s1,40(sp)
    80005d00:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d02:	ffffc097          	auipc	ra,0xffffc
    80005d06:	cc4080e7          	jalr	-828(ra) # 800019c6 <myproc>
    80005d0a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d0c:	fd840593          	addi	a1,s0,-40
    80005d10:	4501                	li	a0,0
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	e7c080e7          	jalr	-388(ra) # 80002b8e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d1a:	fc840593          	addi	a1,s0,-56
    80005d1e:	fd040513          	addi	a0,s0,-48
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	dd6080e7          	jalr	-554(ra) # 80004af8 <pipealloc>
    return -1;
    80005d2a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d2c:	0c054463          	bltz	a0,80005df4 <sys_pipe+0xfc>
  fd0 = -1;
    80005d30:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d34:	fd043503          	ld	a0,-48(s0)
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	518080e7          	jalr	1304(ra) # 80005250 <fdalloc>
    80005d40:	fca42223          	sw	a0,-60(s0)
    80005d44:	08054b63          	bltz	a0,80005dda <sys_pipe+0xe2>
    80005d48:	fc843503          	ld	a0,-56(s0)
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	504080e7          	jalr	1284(ra) # 80005250 <fdalloc>
    80005d54:	fca42023          	sw	a0,-64(s0)
    80005d58:	06054863          	bltz	a0,80005dc8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d5c:	4691                	li	a3,4
    80005d5e:	fc440613          	addi	a2,s0,-60
    80005d62:	fd843583          	ld	a1,-40(s0)
    80005d66:	68a8                	ld	a0,80(s1)
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	91c080e7          	jalr	-1764(ra) # 80001684 <copyout>
    80005d70:	02054063          	bltz	a0,80005d90 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d74:	4691                	li	a3,4
    80005d76:	fc040613          	addi	a2,s0,-64
    80005d7a:	fd843583          	ld	a1,-40(s0)
    80005d7e:	0591                	addi	a1,a1,4
    80005d80:	68a8                	ld	a0,80(s1)
    80005d82:	ffffc097          	auipc	ra,0xffffc
    80005d86:	902080e7          	jalr	-1790(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d8a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d8c:	06055463          	bgez	a0,80005df4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d90:	fc442783          	lw	a5,-60(s0)
    80005d94:	07e9                	addi	a5,a5,26
    80005d96:	078e                	slli	a5,a5,0x3
    80005d98:	97a6                	add	a5,a5,s1
    80005d9a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d9e:	fc042503          	lw	a0,-64(s0)
    80005da2:	0569                	addi	a0,a0,26
    80005da4:	050e                	slli	a0,a0,0x3
    80005da6:	94aa                	add	s1,s1,a0
    80005da8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dac:	fd043503          	ld	a0,-48(s0)
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	a18080e7          	jalr	-1512(ra) # 800047c8 <fileclose>
    fileclose(wf);
    80005db8:	fc843503          	ld	a0,-56(s0)
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	a0c080e7          	jalr	-1524(ra) # 800047c8 <fileclose>
    return -1;
    80005dc4:	57fd                	li	a5,-1
    80005dc6:	a03d                	j	80005df4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005dc8:	fc442783          	lw	a5,-60(s0)
    80005dcc:	0007c763          	bltz	a5,80005dda <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005dd0:	07e9                	addi	a5,a5,26
    80005dd2:	078e                	slli	a5,a5,0x3
    80005dd4:	94be                	add	s1,s1,a5
    80005dd6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dda:	fd043503          	ld	a0,-48(s0)
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	9ea080e7          	jalr	-1558(ra) # 800047c8 <fileclose>
    fileclose(wf);
    80005de6:	fc843503          	ld	a0,-56(s0)
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	9de080e7          	jalr	-1570(ra) # 800047c8 <fileclose>
    return -1;
    80005df2:	57fd                	li	a5,-1
}
    80005df4:	853e                	mv	a0,a5
    80005df6:	70e2                	ld	ra,56(sp)
    80005df8:	7442                	ld	s0,48(sp)
    80005dfa:	74a2                	ld	s1,40(sp)
    80005dfc:	6121                	addi	sp,sp,64
    80005dfe:	8082                	ret

0000000080005e00 <kernelvec>:
    80005e00:	7111                	addi	sp,sp,-256
    80005e02:	e006                	sd	ra,0(sp)
    80005e04:	e40a                	sd	sp,8(sp)
    80005e06:	e80e                	sd	gp,16(sp)
    80005e08:	ec12                	sd	tp,24(sp)
    80005e0a:	f016                	sd	t0,32(sp)
    80005e0c:	f41a                	sd	t1,40(sp)
    80005e0e:	f81e                	sd	t2,48(sp)
    80005e10:	fc22                	sd	s0,56(sp)
    80005e12:	e0a6                	sd	s1,64(sp)
    80005e14:	e4aa                	sd	a0,72(sp)
    80005e16:	e8ae                	sd	a1,80(sp)
    80005e18:	ecb2                	sd	a2,88(sp)
    80005e1a:	f0b6                	sd	a3,96(sp)
    80005e1c:	f4ba                	sd	a4,104(sp)
    80005e1e:	f8be                	sd	a5,112(sp)
    80005e20:	fcc2                	sd	a6,120(sp)
    80005e22:	e146                	sd	a7,128(sp)
    80005e24:	e54a                	sd	s2,136(sp)
    80005e26:	e94e                	sd	s3,144(sp)
    80005e28:	ed52                	sd	s4,152(sp)
    80005e2a:	f156                	sd	s5,160(sp)
    80005e2c:	f55a                	sd	s6,168(sp)
    80005e2e:	f95e                	sd	s7,176(sp)
    80005e30:	fd62                	sd	s8,184(sp)
    80005e32:	e1e6                	sd	s9,192(sp)
    80005e34:	e5ea                	sd	s10,200(sp)
    80005e36:	e9ee                	sd	s11,208(sp)
    80005e38:	edf2                	sd	t3,216(sp)
    80005e3a:	f1f6                	sd	t4,224(sp)
    80005e3c:	f5fa                	sd	t5,232(sp)
    80005e3e:	f9fe                	sd	t6,240(sp)
    80005e40:	b5ffc0ef          	jal	ra,8000299e <kerneltrap>
    80005e44:	6082                	ld	ra,0(sp)
    80005e46:	6122                	ld	sp,8(sp)
    80005e48:	61c2                	ld	gp,16(sp)
    80005e4a:	7282                	ld	t0,32(sp)
    80005e4c:	7322                	ld	t1,40(sp)
    80005e4e:	73c2                	ld	t2,48(sp)
    80005e50:	7462                	ld	s0,56(sp)
    80005e52:	6486                	ld	s1,64(sp)
    80005e54:	6526                	ld	a0,72(sp)
    80005e56:	65c6                	ld	a1,80(sp)
    80005e58:	6666                	ld	a2,88(sp)
    80005e5a:	7686                	ld	a3,96(sp)
    80005e5c:	7726                	ld	a4,104(sp)
    80005e5e:	77c6                	ld	a5,112(sp)
    80005e60:	7866                	ld	a6,120(sp)
    80005e62:	688a                	ld	a7,128(sp)
    80005e64:	692a                	ld	s2,136(sp)
    80005e66:	69ca                	ld	s3,144(sp)
    80005e68:	6a6a                	ld	s4,152(sp)
    80005e6a:	7a8a                	ld	s5,160(sp)
    80005e6c:	7b2a                	ld	s6,168(sp)
    80005e6e:	7bca                	ld	s7,176(sp)
    80005e70:	7c6a                	ld	s8,184(sp)
    80005e72:	6c8e                	ld	s9,192(sp)
    80005e74:	6d2e                	ld	s10,200(sp)
    80005e76:	6dce                	ld	s11,208(sp)
    80005e78:	6e6e                	ld	t3,216(sp)
    80005e7a:	7e8e                	ld	t4,224(sp)
    80005e7c:	7f2e                	ld	t5,232(sp)
    80005e7e:	7fce                	ld	t6,240(sp)
    80005e80:	6111                	addi	sp,sp,256
    80005e82:	10200073          	sret
    80005e86:	00000013          	nop
    80005e8a:	00000013          	nop
    80005e8e:	0001                	nop

0000000080005e90 <timervec>:
    80005e90:	34051573          	csrrw	a0,mscratch,a0
    80005e94:	e10c                	sd	a1,0(a0)
    80005e96:	e510                	sd	a2,8(a0)
    80005e98:	e914                	sd	a3,16(a0)
    80005e9a:	6d0c                	ld	a1,24(a0)
    80005e9c:	7110                	ld	a2,32(a0)
    80005e9e:	6194                	ld	a3,0(a1)
    80005ea0:	96b2                	add	a3,a3,a2
    80005ea2:	e194                	sd	a3,0(a1)
    80005ea4:	4589                	li	a1,2
    80005ea6:	14459073          	csrw	sip,a1
    80005eaa:	6914                	ld	a3,16(a0)
    80005eac:	6510                	ld	a2,8(a0)
    80005eae:	610c                	ld	a1,0(a0)
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	30200073          	mret
	...

0000000080005eba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eba:	1141                	addi	sp,sp,-16
    80005ebc:	e422                	sd	s0,8(sp)
    80005ebe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ec0:	0c0007b7          	lui	a5,0xc000
    80005ec4:	4705                	li	a4,1
    80005ec6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ec8:	c3d8                	sw	a4,4(a5)
}
    80005eca:	6422                	ld	s0,8(sp)
    80005ecc:	0141                	addi	sp,sp,16
    80005ece:	8082                	ret

0000000080005ed0 <plicinithart>:

void
plicinithart(void)
{
    80005ed0:	1141                	addi	sp,sp,-16
    80005ed2:	e406                	sd	ra,8(sp)
    80005ed4:	e022                	sd	s0,0(sp)
    80005ed6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ed8:	ffffc097          	auipc	ra,0xffffc
    80005edc:	ac2080e7          	jalr	-1342(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ee0:	0085171b          	slliw	a4,a0,0x8
    80005ee4:	0c0027b7          	lui	a5,0xc002
    80005ee8:	97ba                	add	a5,a5,a4
    80005eea:	40200713          	li	a4,1026
    80005eee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ef2:	00d5151b          	slliw	a0,a0,0xd
    80005ef6:	0c2017b7          	lui	a5,0xc201
    80005efa:	953e                	add	a0,a0,a5
    80005efc:	00052023          	sw	zero,0(a0)
}
    80005f00:	60a2                	ld	ra,8(sp)
    80005f02:	6402                	ld	s0,0(sp)
    80005f04:	0141                	addi	sp,sp,16
    80005f06:	8082                	ret

0000000080005f08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f08:	1141                	addi	sp,sp,-16
    80005f0a:	e406                	sd	ra,8(sp)
    80005f0c:	e022                	sd	s0,0(sp)
    80005f0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f10:	ffffc097          	auipc	ra,0xffffc
    80005f14:	a8a080e7          	jalr	-1398(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f18:	00d5179b          	slliw	a5,a0,0xd
    80005f1c:	0c201537          	lui	a0,0xc201
    80005f20:	953e                	add	a0,a0,a5
  return irq;
}
    80005f22:	4148                	lw	a0,4(a0)
    80005f24:	60a2                	ld	ra,8(sp)
    80005f26:	6402                	ld	s0,0(sp)
    80005f28:	0141                	addi	sp,sp,16
    80005f2a:	8082                	ret

0000000080005f2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f2c:	1101                	addi	sp,sp,-32
    80005f2e:	ec06                	sd	ra,24(sp)
    80005f30:	e822                	sd	s0,16(sp)
    80005f32:	e426                	sd	s1,8(sp)
    80005f34:	1000                	addi	s0,sp,32
    80005f36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	a62080e7          	jalr	-1438(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f40:	00d5151b          	slliw	a0,a0,0xd
    80005f44:	0c2017b7          	lui	a5,0xc201
    80005f48:	97aa                	add	a5,a5,a0
    80005f4a:	c3c4                	sw	s1,4(a5)
}
    80005f4c:	60e2                	ld	ra,24(sp)
    80005f4e:	6442                	ld	s0,16(sp)
    80005f50:	64a2                	ld	s1,8(sp)
    80005f52:	6105                	addi	sp,sp,32
    80005f54:	8082                	ret

0000000080005f56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f56:	1141                	addi	sp,sp,-16
    80005f58:	e406                	sd	ra,8(sp)
    80005f5a:	e022                	sd	s0,0(sp)
    80005f5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f5e:	479d                	li	a5,7
    80005f60:	04a7cc63          	blt	a5,a0,80005fb8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f64:	0001c797          	auipc	a5,0x1c
    80005f68:	74c78793          	addi	a5,a5,1868 # 800226b0 <disk>
    80005f6c:	97aa                	add	a5,a5,a0
    80005f6e:	0187c783          	lbu	a5,24(a5)
    80005f72:	ebb9                	bnez	a5,80005fc8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f74:	00451613          	slli	a2,a0,0x4
    80005f78:	0001c797          	auipc	a5,0x1c
    80005f7c:	73878793          	addi	a5,a5,1848 # 800226b0 <disk>
    80005f80:	6394                	ld	a3,0(a5)
    80005f82:	96b2                	add	a3,a3,a2
    80005f84:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f88:	6398                	ld	a4,0(a5)
    80005f8a:	9732                	add	a4,a4,a2
    80005f8c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f90:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f94:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f98:	953e                	add	a0,a0,a5
    80005f9a:	4785                	li	a5,1
    80005f9c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005fa0:	0001c517          	auipc	a0,0x1c
    80005fa4:	72850513          	addi	a0,a0,1832 # 800226c8 <disk+0x18>
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	162080e7          	jalr	354(ra) # 8000210a <wakeup>
}
    80005fb0:	60a2                	ld	ra,8(sp)
    80005fb2:	6402                	ld	s0,0(sp)
    80005fb4:	0141                	addi	sp,sp,16
    80005fb6:	8082                	ret
    panic("free_desc 1");
    80005fb8:	00003517          	auipc	a0,0x3
    80005fbc:	92850513          	addi	a0,a0,-1752 # 800088e0 <syscalls+0x300>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	584080e7          	jalr	1412(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005fc8:	00003517          	auipc	a0,0x3
    80005fcc:	92850513          	addi	a0,a0,-1752 # 800088f0 <syscalls+0x310>
    80005fd0:	ffffa097          	auipc	ra,0xffffa
    80005fd4:	574080e7          	jalr	1396(ra) # 80000544 <panic>

0000000080005fd8 <virtio_disk_init>:
{
    80005fd8:	1101                	addi	sp,sp,-32
    80005fda:	ec06                	sd	ra,24(sp)
    80005fdc:	e822                	sd	s0,16(sp)
    80005fde:	e426                	sd	s1,8(sp)
    80005fe0:	e04a                	sd	s2,0(sp)
    80005fe2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fe4:	00003597          	auipc	a1,0x3
    80005fe8:	91c58593          	addi	a1,a1,-1764 # 80008900 <syscalls+0x320>
    80005fec:	0001c517          	auipc	a0,0x1c
    80005ff0:	7ec50513          	addi	a0,a0,2028 # 800227d8 <disk+0x128>
    80005ff4:	ffffb097          	auipc	ra,0xffffb
    80005ff8:	b66080e7          	jalr	-1178(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ffc:	100017b7          	lui	a5,0x10001
    80006000:	4398                	lw	a4,0(a5)
    80006002:	2701                	sext.w	a4,a4
    80006004:	747277b7          	lui	a5,0x74727
    80006008:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000600c:	14f71e63          	bne	a4,a5,80006168 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006010:	100017b7          	lui	a5,0x10001
    80006014:	43dc                	lw	a5,4(a5)
    80006016:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006018:	4709                	li	a4,2
    8000601a:	14e79763          	bne	a5,a4,80006168 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000601e:	100017b7          	lui	a5,0x10001
    80006022:	479c                	lw	a5,8(a5)
    80006024:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006026:	14e79163          	bne	a5,a4,80006168 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000602a:	100017b7          	lui	a5,0x10001
    8000602e:	47d8                	lw	a4,12(a5)
    80006030:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006032:	554d47b7          	lui	a5,0x554d4
    80006036:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000603a:	12f71763          	bne	a4,a5,80006168 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000603e:	100017b7          	lui	a5,0x10001
    80006042:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006046:	4705                	li	a4,1
    80006048:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604a:	470d                	li	a4,3
    8000604c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000604e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006050:	c7ffe737          	lui	a4,0xc7ffe
    80006054:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbf6f>
    80006058:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000605a:	2701                	sext.w	a4,a4
    8000605c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	472d                	li	a4,11
    80006060:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006062:	0707a903          	lw	s2,112(a5)
    80006066:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006068:	00897793          	andi	a5,s2,8
    8000606c:	10078663          	beqz	a5,80006178 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006070:	100017b7          	lui	a5,0x10001
    80006074:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006078:	43fc                	lw	a5,68(a5)
    8000607a:	2781                	sext.w	a5,a5
    8000607c:	10079663          	bnez	a5,80006188 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006080:	100017b7          	lui	a5,0x10001
    80006084:	5bdc                	lw	a5,52(a5)
    80006086:	2781                	sext.w	a5,a5
  if(max == 0)
    80006088:	10078863          	beqz	a5,80006198 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000608c:	471d                	li	a4,7
    8000608e:	10f77d63          	bgeu	a4,a5,800061a8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006092:	ffffb097          	auipc	ra,0xffffb
    80006096:	a68080e7          	jalr	-1432(ra) # 80000afa <kalloc>
    8000609a:	0001c497          	auipc	s1,0x1c
    8000609e:	61648493          	addi	s1,s1,1558 # 800226b0 <disk>
    800060a2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060a4:	ffffb097          	auipc	ra,0xffffb
    800060a8:	a56080e7          	jalr	-1450(ra) # 80000afa <kalloc>
    800060ac:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ae:	ffffb097          	auipc	ra,0xffffb
    800060b2:	a4c080e7          	jalr	-1460(ra) # 80000afa <kalloc>
    800060b6:	87aa                	mv	a5,a0
    800060b8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060ba:	6088                	ld	a0,0(s1)
    800060bc:	cd75                	beqz	a0,800061b8 <virtio_disk_init+0x1e0>
    800060be:	0001c717          	auipc	a4,0x1c
    800060c2:	5fa73703          	ld	a4,1530(a4) # 800226b8 <disk+0x8>
    800060c6:	cb6d                	beqz	a4,800061b8 <virtio_disk_init+0x1e0>
    800060c8:	cbe5                	beqz	a5,800061b8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800060ca:	6605                	lui	a2,0x1
    800060cc:	4581                	li	a1,0
    800060ce:	ffffb097          	auipc	ra,0xffffb
    800060d2:	c18080e7          	jalr	-1000(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060d6:	0001c497          	auipc	s1,0x1c
    800060da:	5da48493          	addi	s1,s1,1498 # 800226b0 <disk>
    800060de:	6605                	lui	a2,0x1
    800060e0:	4581                	li	a1,0
    800060e2:	6488                	ld	a0,8(s1)
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	c02080e7          	jalr	-1022(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    800060ec:	6605                	lui	a2,0x1
    800060ee:	4581                	li	a1,0
    800060f0:	6888                	ld	a0,16(s1)
    800060f2:	ffffb097          	auipc	ra,0xffffb
    800060f6:	bf4080e7          	jalr	-1036(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060fa:	100017b7          	lui	a5,0x10001
    800060fe:	4721                	li	a4,8
    80006100:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006102:	4098                	lw	a4,0(s1)
    80006104:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006108:	40d8                	lw	a4,4(s1)
    8000610a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000610e:	6498                	ld	a4,8(s1)
    80006110:	0007069b          	sext.w	a3,a4
    80006114:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006118:	9701                	srai	a4,a4,0x20
    8000611a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000611e:	6898                	ld	a4,16(s1)
    80006120:	0007069b          	sext.w	a3,a4
    80006124:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006128:	9701                	srai	a4,a4,0x20
    8000612a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000612e:	4685                	li	a3,1
    80006130:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006132:	4705                	li	a4,1
    80006134:	00d48c23          	sb	a3,24(s1)
    80006138:	00e48ca3          	sb	a4,25(s1)
    8000613c:	00e48d23          	sb	a4,26(s1)
    80006140:	00e48da3          	sb	a4,27(s1)
    80006144:	00e48e23          	sb	a4,28(s1)
    80006148:	00e48ea3          	sb	a4,29(s1)
    8000614c:	00e48f23          	sb	a4,30(s1)
    80006150:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006154:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006158:	0727a823          	sw	s2,112(a5)
}
    8000615c:	60e2                	ld	ra,24(sp)
    8000615e:	6442                	ld	s0,16(sp)
    80006160:	64a2                	ld	s1,8(sp)
    80006162:	6902                	ld	s2,0(sp)
    80006164:	6105                	addi	sp,sp,32
    80006166:	8082                	ret
    panic("could not find virtio disk");
    80006168:	00002517          	auipc	a0,0x2
    8000616c:	7a850513          	addi	a0,a0,1960 # 80008910 <syscalls+0x330>
    80006170:	ffffa097          	auipc	ra,0xffffa
    80006174:	3d4080e7          	jalr	980(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006178:	00002517          	auipc	a0,0x2
    8000617c:	7b850513          	addi	a0,a0,1976 # 80008930 <syscalls+0x350>
    80006180:	ffffa097          	auipc	ra,0xffffa
    80006184:	3c4080e7          	jalr	964(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006188:	00002517          	auipc	a0,0x2
    8000618c:	7c850513          	addi	a0,a0,1992 # 80008950 <syscalls+0x370>
    80006190:	ffffa097          	auipc	ra,0xffffa
    80006194:	3b4080e7          	jalr	948(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006198:	00002517          	auipc	a0,0x2
    8000619c:	7d850513          	addi	a0,a0,2008 # 80008970 <syscalls+0x390>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	3a4080e7          	jalr	932(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	7e850513          	addi	a0,a0,2024 # 80008990 <syscalls+0x3b0>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	394080e7          	jalr	916(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800061b8:	00002517          	auipc	a0,0x2
    800061bc:	7f850513          	addi	a0,a0,2040 # 800089b0 <syscalls+0x3d0>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	384080e7          	jalr	900(ra) # 80000544 <panic>

00000000800061c8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061c8:	7159                	addi	sp,sp,-112
    800061ca:	f486                	sd	ra,104(sp)
    800061cc:	f0a2                	sd	s0,96(sp)
    800061ce:	eca6                	sd	s1,88(sp)
    800061d0:	e8ca                	sd	s2,80(sp)
    800061d2:	e4ce                	sd	s3,72(sp)
    800061d4:	e0d2                	sd	s4,64(sp)
    800061d6:	fc56                	sd	s5,56(sp)
    800061d8:	f85a                	sd	s6,48(sp)
    800061da:	f45e                	sd	s7,40(sp)
    800061dc:	f062                	sd	s8,32(sp)
    800061de:	ec66                	sd	s9,24(sp)
    800061e0:	e86a                	sd	s10,16(sp)
    800061e2:	1880                	addi	s0,sp,112
    800061e4:	892a                	mv	s2,a0
    800061e6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061e8:	00c52c83          	lw	s9,12(a0)
    800061ec:	001c9c9b          	slliw	s9,s9,0x1
    800061f0:	1c82                	slli	s9,s9,0x20
    800061f2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061f6:	0001c517          	auipc	a0,0x1c
    800061fa:	5e250513          	addi	a0,a0,1506 # 800227d8 <disk+0x128>
    800061fe:	ffffb097          	auipc	ra,0xffffb
    80006202:	9ec080e7          	jalr	-1556(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006206:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006208:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000620a:	0001cb17          	auipc	s6,0x1c
    8000620e:	4a6b0b13          	addi	s6,s6,1190 # 800226b0 <disk>
  for(int i = 0; i < 3; i++){
    80006212:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006214:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006216:	0001cc17          	auipc	s8,0x1c
    8000621a:	5c2c0c13          	addi	s8,s8,1474 # 800227d8 <disk+0x128>
    8000621e:	a8b5                	j	8000629a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006220:	00fb06b3          	add	a3,s6,a5
    80006224:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006228:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000622a:	0207c563          	bltz	a5,80006254 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000622e:	2485                	addiw	s1,s1,1
    80006230:	0711                	addi	a4,a4,4
    80006232:	1f548a63          	beq	s1,s5,80006426 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006236:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006238:	0001c697          	auipc	a3,0x1c
    8000623c:	47868693          	addi	a3,a3,1144 # 800226b0 <disk>
    80006240:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006242:	0186c583          	lbu	a1,24(a3)
    80006246:	fde9                	bnez	a1,80006220 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006248:	2785                	addiw	a5,a5,1
    8000624a:	0685                	addi	a3,a3,1
    8000624c:	ff779be3          	bne	a5,s7,80006242 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006250:	57fd                	li	a5,-1
    80006252:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006254:	02905a63          	blez	s1,80006288 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006258:	f9042503          	lw	a0,-112(s0)
    8000625c:	00000097          	auipc	ra,0x0
    80006260:	cfa080e7          	jalr	-774(ra) # 80005f56 <free_desc>
      for(int j = 0; j < i; j++)
    80006264:	4785                	li	a5,1
    80006266:	0297d163          	bge	a5,s1,80006288 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000626a:	f9442503          	lw	a0,-108(s0)
    8000626e:	00000097          	auipc	ra,0x0
    80006272:	ce8080e7          	jalr	-792(ra) # 80005f56 <free_desc>
      for(int j = 0; j < i; j++)
    80006276:	4789                	li	a5,2
    80006278:	0097d863          	bge	a5,s1,80006288 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000627c:	f9842503          	lw	a0,-104(s0)
    80006280:	00000097          	auipc	ra,0x0
    80006284:	cd6080e7          	jalr	-810(ra) # 80005f56 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006288:	85e2                	mv	a1,s8
    8000628a:	0001c517          	auipc	a0,0x1c
    8000628e:	43e50513          	addi	a0,a0,1086 # 800226c8 <disk+0x18>
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	e14080e7          	jalr	-492(ra) # 800020a6 <sleep>
  for(int i = 0; i < 3; i++){
    8000629a:	f9040713          	addi	a4,s0,-112
    8000629e:	84ce                	mv	s1,s3
    800062a0:	bf59                	j	80006236 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800062a2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800062a6:	00479693          	slli	a3,a5,0x4
    800062aa:	0001c797          	auipc	a5,0x1c
    800062ae:	40678793          	addi	a5,a5,1030 # 800226b0 <disk>
    800062b2:	97b6                	add	a5,a5,a3
    800062b4:	4685                	li	a3,1
    800062b6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062b8:	0001c597          	auipc	a1,0x1c
    800062bc:	3f858593          	addi	a1,a1,1016 # 800226b0 <disk>
    800062c0:	00a60793          	addi	a5,a2,10
    800062c4:	0792                	slli	a5,a5,0x4
    800062c6:	97ae                	add	a5,a5,a1
    800062c8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800062cc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062d0:	f6070693          	addi	a3,a4,-160
    800062d4:	619c                	ld	a5,0(a1)
    800062d6:	97b6                	add	a5,a5,a3
    800062d8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062da:	6188                	ld	a0,0(a1)
    800062dc:	96aa                	add	a3,a3,a0
    800062de:	47c1                	li	a5,16
    800062e0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062e2:	4785                	li	a5,1
    800062e4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800062e8:	f9442783          	lw	a5,-108(s0)
    800062ec:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062f0:	0792                	slli	a5,a5,0x4
    800062f2:	953e                	add	a0,a0,a5
    800062f4:	05890693          	addi	a3,s2,88
    800062f8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800062fa:	6188                	ld	a0,0(a1)
    800062fc:	97aa                	add	a5,a5,a0
    800062fe:	40000693          	li	a3,1024
    80006302:	c794                	sw	a3,8(a5)
  if(write)
    80006304:	100d0d63          	beqz	s10,8000641e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006308:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000630c:	00c7d683          	lhu	a3,12(a5)
    80006310:	0016e693          	ori	a3,a3,1
    80006314:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006318:	f9842583          	lw	a1,-104(s0)
    8000631c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006320:	0001c697          	auipc	a3,0x1c
    80006324:	39068693          	addi	a3,a3,912 # 800226b0 <disk>
    80006328:	00260793          	addi	a5,a2,2
    8000632c:	0792                	slli	a5,a5,0x4
    8000632e:	97b6                	add	a5,a5,a3
    80006330:	587d                	li	a6,-1
    80006332:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006336:	0592                	slli	a1,a1,0x4
    80006338:	952e                	add	a0,a0,a1
    8000633a:	f9070713          	addi	a4,a4,-112
    8000633e:	9736                	add	a4,a4,a3
    80006340:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006342:	6298                	ld	a4,0(a3)
    80006344:	972e                	add	a4,a4,a1
    80006346:	4585                	li	a1,1
    80006348:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000634a:	4509                	li	a0,2
    8000634c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006350:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006354:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006358:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000635c:	6698                	ld	a4,8(a3)
    8000635e:	00275783          	lhu	a5,2(a4)
    80006362:	8b9d                	andi	a5,a5,7
    80006364:	0786                	slli	a5,a5,0x1
    80006366:	97ba                	add	a5,a5,a4
    80006368:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000636c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006370:	6698                	ld	a4,8(a3)
    80006372:	00275783          	lhu	a5,2(a4)
    80006376:	2785                	addiw	a5,a5,1
    80006378:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000637c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006380:	100017b7          	lui	a5,0x10001
    80006384:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006388:	00492703          	lw	a4,4(s2)
    8000638c:	4785                	li	a5,1
    8000638e:	02f71163          	bne	a4,a5,800063b0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006392:	0001c997          	auipc	s3,0x1c
    80006396:	44698993          	addi	s3,s3,1094 # 800227d8 <disk+0x128>
  while(b->disk == 1) {
    8000639a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000639c:	85ce                	mv	a1,s3
    8000639e:	854a                	mv	a0,s2
    800063a0:	ffffc097          	auipc	ra,0xffffc
    800063a4:	d06080e7          	jalr	-762(ra) # 800020a6 <sleep>
  while(b->disk == 1) {
    800063a8:	00492783          	lw	a5,4(s2)
    800063ac:	fe9788e3          	beq	a5,s1,8000639c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800063b0:	f9042903          	lw	s2,-112(s0)
    800063b4:	00290793          	addi	a5,s2,2
    800063b8:	00479713          	slli	a4,a5,0x4
    800063bc:	0001c797          	auipc	a5,0x1c
    800063c0:	2f478793          	addi	a5,a5,756 # 800226b0 <disk>
    800063c4:	97ba                	add	a5,a5,a4
    800063c6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063ca:	0001c997          	auipc	s3,0x1c
    800063ce:	2e698993          	addi	s3,s3,742 # 800226b0 <disk>
    800063d2:	00491713          	slli	a4,s2,0x4
    800063d6:	0009b783          	ld	a5,0(s3)
    800063da:	97ba                	add	a5,a5,a4
    800063dc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063e0:	854a                	mv	a0,s2
    800063e2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063e6:	00000097          	auipc	ra,0x0
    800063ea:	b70080e7          	jalr	-1168(ra) # 80005f56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063ee:	8885                	andi	s1,s1,1
    800063f0:	f0ed                	bnez	s1,800063d2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063f2:	0001c517          	auipc	a0,0x1c
    800063f6:	3e650513          	addi	a0,a0,998 # 800227d8 <disk+0x128>
    800063fa:	ffffb097          	auipc	ra,0xffffb
    800063fe:	8a4080e7          	jalr	-1884(ra) # 80000c9e <release>
}
    80006402:	70a6                	ld	ra,104(sp)
    80006404:	7406                	ld	s0,96(sp)
    80006406:	64e6                	ld	s1,88(sp)
    80006408:	6946                	ld	s2,80(sp)
    8000640a:	69a6                	ld	s3,72(sp)
    8000640c:	6a06                	ld	s4,64(sp)
    8000640e:	7ae2                	ld	s5,56(sp)
    80006410:	7b42                	ld	s6,48(sp)
    80006412:	7ba2                	ld	s7,40(sp)
    80006414:	7c02                	ld	s8,32(sp)
    80006416:	6ce2                	ld	s9,24(sp)
    80006418:	6d42                	ld	s10,16(sp)
    8000641a:	6165                	addi	sp,sp,112
    8000641c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000641e:	4689                	li	a3,2
    80006420:	00d79623          	sh	a3,12(a5)
    80006424:	b5e5                	j	8000630c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006426:	f9042603          	lw	a2,-112(s0)
    8000642a:	00a60713          	addi	a4,a2,10
    8000642e:	0712                	slli	a4,a4,0x4
    80006430:	0001c517          	auipc	a0,0x1c
    80006434:	28850513          	addi	a0,a0,648 # 800226b8 <disk+0x8>
    80006438:	953a                	add	a0,a0,a4
  if(write)
    8000643a:	e60d14e3          	bnez	s10,800062a2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000643e:	00a60793          	addi	a5,a2,10
    80006442:	00479693          	slli	a3,a5,0x4
    80006446:	0001c797          	auipc	a5,0x1c
    8000644a:	26a78793          	addi	a5,a5,618 # 800226b0 <disk>
    8000644e:	97b6                	add	a5,a5,a3
    80006450:	0007a423          	sw	zero,8(a5)
    80006454:	b595                	j	800062b8 <virtio_disk_rw+0xf0>

0000000080006456 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006456:	1101                	addi	sp,sp,-32
    80006458:	ec06                	sd	ra,24(sp)
    8000645a:	e822                	sd	s0,16(sp)
    8000645c:	e426                	sd	s1,8(sp)
    8000645e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006460:	0001c497          	auipc	s1,0x1c
    80006464:	25048493          	addi	s1,s1,592 # 800226b0 <disk>
    80006468:	0001c517          	auipc	a0,0x1c
    8000646c:	37050513          	addi	a0,a0,880 # 800227d8 <disk+0x128>
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	77a080e7          	jalr	1914(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006478:	10001737          	lui	a4,0x10001
    8000647c:	533c                	lw	a5,96(a4)
    8000647e:	8b8d                	andi	a5,a5,3
    80006480:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006482:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006486:	689c                	ld	a5,16(s1)
    80006488:	0204d703          	lhu	a4,32(s1)
    8000648c:	0027d783          	lhu	a5,2(a5)
    80006490:	04f70863          	beq	a4,a5,800064e0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006494:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006498:	6898                	ld	a4,16(s1)
    8000649a:	0204d783          	lhu	a5,32(s1)
    8000649e:	8b9d                	andi	a5,a5,7
    800064a0:	078e                	slli	a5,a5,0x3
    800064a2:	97ba                	add	a5,a5,a4
    800064a4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064a6:	00278713          	addi	a4,a5,2
    800064aa:	0712                	slli	a4,a4,0x4
    800064ac:	9726                	add	a4,a4,s1
    800064ae:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064b2:	e721                	bnez	a4,800064fa <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064b4:	0789                	addi	a5,a5,2
    800064b6:	0792                	slli	a5,a5,0x4
    800064b8:	97a6                	add	a5,a5,s1
    800064ba:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064bc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064c0:	ffffc097          	auipc	ra,0xffffc
    800064c4:	c4a080e7          	jalr	-950(ra) # 8000210a <wakeup>

    disk.used_idx += 1;
    800064c8:	0204d783          	lhu	a5,32(s1)
    800064cc:	2785                	addiw	a5,a5,1
    800064ce:	17c2                	slli	a5,a5,0x30
    800064d0:	93c1                	srli	a5,a5,0x30
    800064d2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064d6:	6898                	ld	a4,16(s1)
    800064d8:	00275703          	lhu	a4,2(a4)
    800064dc:	faf71ce3          	bne	a4,a5,80006494 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800064e0:	0001c517          	auipc	a0,0x1c
    800064e4:	2f850513          	addi	a0,a0,760 # 800227d8 <disk+0x128>
    800064e8:	ffffa097          	auipc	ra,0xffffa
    800064ec:	7b6080e7          	jalr	1974(ra) # 80000c9e <release>
}
    800064f0:	60e2                	ld	ra,24(sp)
    800064f2:	6442                	ld	s0,16(sp)
    800064f4:	64a2                	ld	s1,8(sp)
    800064f6:	6105                	addi	sp,sp,32
    800064f8:	8082                	ret
      panic("virtio_disk_intr status");
    800064fa:	00002517          	auipc	a0,0x2
    800064fe:	4ce50513          	addi	a0,a0,1230 # 800089c8 <syscalls+0x3e8>
    80006502:	ffffa097          	auipc	ra,0xffffa
    80006506:	042080e7          	jalr	66(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
