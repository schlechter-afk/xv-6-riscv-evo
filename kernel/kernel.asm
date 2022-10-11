
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	e1010113          	addi	sp,sp,-496 # 80008e10 <stack0>
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
    80000056:	c7e70713          	addi	a4,a4,-898 # 80008cd0 <timer_scratch>
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
    80000068:	66c78793          	addi	a5,a5,1644 # 800066d0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb9b3f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f2678793          	addi	a5,a5,-218 # 80000fd4 <main>
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
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	b24080e7          	jalr	-1244(ra) # 80002c50 <either_copyin>
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
    80000190:	c8450513          	addi	a0,a0,-892 # 80010e10 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	b96080e7          	jalr	-1130(ra) # 80000d2a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	c7448493          	addi	s1,s1,-908 # 80010e10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	d0290913          	addi	s2,s2,-766 # 80010ea8 <cons+0x98>
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
    800001c8:	b9a080e7          	jalr	-1126(ra) # 80001d5e <myproc>
    800001cc:	00003097          	auipc	ra,0x3
    800001d0:	9fc080e7          	jalr	-1540(ra) # 80002bc8 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	4c2080e7          	jalr	1218(ra) # 8000269c <sleep>
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
    80000216:	00003097          	auipc	ra,0x3
    8000021a:	9e4080e7          	jalr	-1564(ra) # 80002bfa <either_copyout>
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
    8000022e:	be650513          	addi	a0,a0,-1050 # 80010e10 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	bac080e7          	jalr	-1108(ra) # 80000dde <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	bd050513          	addi	a0,a0,-1072 # 80010e10 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	b96080e7          	jalr	-1130(ra) # 80000dde <release>
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
    8000027c:	c2f72823          	sw	a5,-976(a4) # 80010ea8 <cons+0x98>
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
    800002d6:	b3e50513          	addi	a0,a0,-1218 # 80010e10 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	a50080e7          	jalr	-1456(ra) # 80000d2a <acquire>

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
    800002f8:	00003097          	auipc	ra,0x3
    800002fc:	9ae080e7          	jalr	-1618(ra) # 80002ca6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	b1050513          	addi	a0,a0,-1264 # 80010e10 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	ad6080e7          	jalr	-1322(ra) # 80000dde <release>
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
    80000328:	aec70713          	addi	a4,a4,-1300 # 80010e10 <cons>
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
    80000352:	ac278793          	addi	a5,a5,-1342 # 80010e10 <cons>
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
    80000380:	b2c7a783          	lw	a5,-1236(a5) # 80010ea8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	a8070713          	addi	a4,a4,-1408 # 80010e10 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	a7048493          	addi	s1,s1,-1424 # 80010e10 <cons>
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
    800003e0:	a3470713          	addi	a4,a4,-1484 # 80010e10 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	aaf72f23          	sw	a5,-1346(a4) # 80010eb0 <cons+0xa0>
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
    8000041c:	9f878793          	addi	a5,a5,-1544 # 80010e10 <cons>
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
    80000440:	a6c7a823          	sw	a2,-1424(a5) # 80010eac <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	a6450513          	addi	a0,a0,-1436 # 80010ea8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	52c080e7          	jalr	1324(ra) # 80002978 <wakeup>
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
    8000046a:	9aa50513          	addi	a0,a0,-1622 # 80010e10 <cons>
    8000046e:	00001097          	auipc	ra,0x1
    80000472:	82c080e7          	jalr	-2004(ra) # 80000c9a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00243797          	auipc	a5,0x243
    80000482:	6aa78793          	addi	a5,a5,1706 # 80243b28 <devsw>
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
    80000554:	9807a023          	sw	zero,-1664(a5) # 80010ed0 <pr+0x18>
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
    80000576:	fce50513          	addi	a0,a0,-50 # 80008540 <states.1862+0x1a8>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	70f72623          	sw	a5,1804(a4) # 80008c90 <panicked>
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
    800005c0:	00011d97          	auipc	s11,0x11
    800005c4:	910dad83          	lw	s11,-1776(s11) # 80010ed0 <pr+0x18>
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
    800005fe:	00011517          	auipc	a0,0x11
    80000602:	8ba50513          	addi	a0,a0,-1862 # 80010eb8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	724080e7          	jalr	1828(ra) # 80000d2a <acquire>
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
    80000766:	75650513          	addi	a0,a0,1878 # 80010eb8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	674080e7          	jalr	1652(ra) # 80000dde <release>
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
    80000782:	73a48493          	addi	s1,s1,1850 # 80010eb8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	50a080e7          	jalr	1290(ra) # 80000c9a <initlock>
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
    800007e2:	6fa50513          	addi	a0,a0,1786 # 80010ed8 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	4b4080e7          	jalr	1204(ra) # 80000c9a <initlock>
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
    80000806:	4dc080e7          	jalr	1244(ra) # 80000cde <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	4867a783          	lw	a5,1158(a5) # 80008c90 <panicked>
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
    80000838:	54a080e7          	jalr	1354(ra) # 80000d7e <pop_off>
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
    8000084a:	45273703          	ld	a4,1106(a4) # 80008c98 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	4527b783          	ld	a5,1106(a5) # 80008ca0 <uart_tx_w>
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
    80000874:	668a0a13          	addi	s4,s4,1640 # 80010ed8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	42048493          	addi	s1,s1,1056 # 80008c98 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	42098993          	addi	s3,s3,1056 # 80008ca0 <uart_tx_w>
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
    800008aa:	0d2080e7          	jalr	210(ra) # 80002978 <wakeup>
    
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
    800008e6:	5f650513          	addi	a0,a0,1526 # 80010ed8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	440080e7          	jalr	1088(ra) # 80000d2a <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	39e7a783          	lw	a5,926(a5) # 80008c90 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	3a47b783          	ld	a5,932(a5) # 80008ca0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	39473703          	ld	a4,916(a4) # 80008c98 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	5c8a0a13          	addi	s4,s4,1480 # 80010ed8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	38048493          	addi	s1,s1,896 # 80008c98 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	38090913          	addi	s2,s2,896 # 80008ca0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	d6c080e7          	jalr	-660(ra) # 8000269c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	59248493          	addi	s1,s1,1426 # 80010ed8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	34f73323          	sd	a5,838(a4) # 80008ca0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	472080e7          	jalr	1138(ra) # 80000dde <release>
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
    800009d4:	50848493          	addi	s1,s1,1288 # 80010ed8 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	350080e7          	jalr	848(ra) # 80000d2a <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	3f2080e7          	jalr	1010(ra) # 80000dde <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <incref>:
    kfree(p);
  }
}

void incref(uint64 pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
    80000a0a:	892a                	mv	s2,a0
  int pn = pa / PGSIZE;
    80000a0c:	00c55493          	srli	s1,a0,0xc
  acquire(&kmem.lock);
    80000a10:	00010517          	auipc	a0,0x10
    80000a14:	50050513          	addi	a0,a0,1280 # 80010f10 <kmem>
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	312080e7          	jalr	786(ra) # 80000d2a <acquire>
  if (pa >= PHYSTOP || rc[pn] < 1)
    80000a20:	47c5                	li	a5,17
    80000a22:	07ee                	slli	a5,a5,0x1b
    80000a24:	04f97363          	bgeu	s2,a5,80000a6a <incref+0x6c>
    80000a28:	2481                	sext.w	s1,s1
    80000a2a:	00249713          	slli	a4,s1,0x2
    80000a2e:	00010797          	auipc	a5,0x10
    80000a32:	50278793          	addi	a5,a5,1282 # 80010f30 <rc>
    80000a36:	97ba                	add	a5,a5,a4
    80000a38:	439c                	lw	a5,0(a5)
    80000a3a:	02f05863          	blez	a5,80000a6a <incref+0x6c>
  {
    panic("incref");
  }
  rc[pn]++;
    80000a3e:	048a                	slli	s1,s1,0x2
    80000a40:	00010717          	auipc	a4,0x10
    80000a44:	4f070713          	addi	a4,a4,1264 # 80010f30 <rc>
    80000a48:	94ba                	add	s1,s1,a4
    80000a4a:	2785                	addiw	a5,a5,1
    80000a4c:	c09c                	sw	a5,0(s1)
  release(&kmem.lock);
    80000a4e:	00010517          	auipc	a0,0x10
    80000a52:	4c250513          	addi	a0,a0,1218 # 80010f10 <kmem>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	388080e7          	jalr	904(ra) # 80000dde <release>
}
    80000a5e:	60e2                	ld	ra,24(sp)
    80000a60:	6442                	ld	s0,16(sp)
    80000a62:	64a2                	ld	s1,8(sp)
    80000a64:	6902                	ld	s2,0(sp)
    80000a66:	6105                	addi	sp,sp,32
    80000a68:	8082                	ret
    panic("incref");
    80000a6a:	00007517          	auipc	a0,0x7
    80000a6e:	5f650513          	addi	a0,a0,1526 # 80008060 <digits+0x20>
    80000a72:	00000097          	auipc	ra,0x0
    80000a76:	ad2080e7          	jalr	-1326(ra) # 80000544 <panic>

0000000080000a7a <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000a7a:	1101                	addi	sp,sp,-32
    80000a7c:	ec06                	sd	ra,24(sp)
    80000a7e:	e822                	sd	s0,16(sp)
    80000a80:	e426                	sd	s1,8(sp)
    80000a82:	e04a                	sd	s2,0(sp)
    80000a84:	1000                	addi	s0,sp,32
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a86:	03451793          	slli	a5,a0,0x34
    80000a8a:	ebbd                	bnez	a5,80000b00 <kfree+0x86>
    80000a8c:	84aa                	mv	s1,a0
    80000a8e:	00244797          	auipc	a5,0x244
    80000a92:	23278793          	addi	a5,a5,562 # 80244cc0 <end>
    80000a96:	06f56563          	bltu	a0,a5,80000b00 <kfree+0x86>
    80000a9a:	47c5                	li	a5,17
    80000a9c:	07ee                	slli	a5,a5,0x1b
    80000a9e:	06f57163          	bgeu	a0,a5,80000b00 <kfree+0x86>
  {
    panic("kfree");
  }

  acquire(&kmem.lock);
    80000aa2:	00010517          	auipc	a0,0x10
    80000aa6:	46e50513          	addi	a0,a0,1134 # 80010f10 <kmem>
    80000aaa:	00000097          	auipc	ra,0x0
    80000aae:	280080e7          	jalr	640(ra) # 80000d2a <acquire>
  int pn = (uint64)pa / PGSIZE;
    80000ab2:	00c4d793          	srli	a5,s1,0xc
    80000ab6:	2781                	sext.w	a5,a5
  if (1 > rc[pn])
    80000ab8:	00279693          	slli	a3,a5,0x2
    80000abc:	00010717          	auipc	a4,0x10
    80000ac0:	47470713          	addi	a4,a4,1140 # 80010f30 <rc>
    80000ac4:	9736                	add	a4,a4,a3
    80000ac6:	4318                	lw	a4,0(a4)
    80000ac8:	04e05463          	blez	a4,80000b10 <kfree+0x96>
  {
    panic("kfree: ref");
  }
  rc[pn]--;
    80000acc:	377d                	addiw	a4,a4,-1
    80000ace:	0007091b          	sext.w	s2,a4
    80000ad2:	078a                	slli	a5,a5,0x2
    80000ad4:	00010697          	auipc	a3,0x10
    80000ad8:	45c68693          	addi	a3,a3,1116 # 80010f30 <rc>
    80000adc:	97b6                	add	a5,a5,a3
    80000ade:	c398                	sw	a4,0(a5)
  int tmp = rc[pn];
  release(&kmem.lock);
    80000ae0:	00010517          	auipc	a0,0x10
    80000ae4:	43050513          	addi	a0,a0,1072 # 80010f10 <kmem>
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	2f6080e7          	jalr	758(ra) # 80000dde <release>

  if (0 < tmp)
    80000af0:	03205863          	blez	s2,80000b20 <kfree+0xa6>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000af4:	60e2                	ld	ra,24(sp)
    80000af6:	6442                	ld	s0,16(sp)
    80000af8:	64a2                	ld	s1,8(sp)
    80000afa:	6902                	ld	s2,0(sp)
    80000afc:	6105                	addi	sp,sp,32
    80000afe:	8082                	ret
    panic("kfree");
    80000b00:	00007517          	auipc	a0,0x7
    80000b04:	56850513          	addi	a0,a0,1384 # 80008068 <digits+0x28>
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	a3c080e7          	jalr	-1476(ra) # 80000544 <panic>
    panic("kfree: ref");
    80000b10:	00007517          	auipc	a0,0x7
    80000b14:	56050513          	addi	a0,a0,1376 # 80008070 <digits+0x30>
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	a2c080e7          	jalr	-1492(ra) # 80000544 <panic>
  memset(pa, 1, PGSIZE);
    80000b20:	6605                	lui	a2,0x1
    80000b22:	4585                	li	a1,1
    80000b24:	8526                	mv	a0,s1
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	300080e7          	jalr	768(ra) # 80000e26 <memset>
  acquire(&kmem.lock);
    80000b2e:	00010917          	auipc	s2,0x10
    80000b32:	3e290913          	addi	s2,s2,994 # 80010f10 <kmem>
    80000b36:	854a                	mv	a0,s2
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	1f2080e7          	jalr	498(ra) # 80000d2a <acquire>
  r->next = kmem.freelist;
    80000b40:	01893783          	ld	a5,24(s2)
    80000b44:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b46:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b4a:	854a                	mv	a0,s2
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	292080e7          	jalr	658(ra) # 80000dde <release>
    80000b54:	b745                	j	80000af4 <kfree+0x7a>

0000000080000b56 <freerange>:
{
    80000b56:	7139                	addi	sp,sp,-64
    80000b58:	fc06                	sd	ra,56(sp)
    80000b5a:	f822                	sd	s0,48(sp)
    80000b5c:	f426                	sd	s1,40(sp)
    80000b5e:	f04a                	sd	s2,32(sp)
    80000b60:	ec4e                	sd	s3,24(sp)
    80000b62:	e852                	sd	s4,16(sp)
    80000b64:	e456                	sd	s5,8(sp)
    80000b66:	e05a                	sd	s6,0(sp)
    80000b68:	0080                	addi	s0,sp,64
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000b6a:	6785                	lui	a5,0x1
    80000b6c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b70:	9526                	add	a0,a0,s1
    80000b72:	74fd                	lui	s1,0xfffff
    80000b74:	8ce9                	and	s1,s1,a0
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b76:	97a6                	add	a5,a5,s1
    80000b78:	02f5ea63          	bltu	a1,a5,80000bac <freerange+0x56>
    80000b7c:	892e                	mv	s2,a1
    rc[(uint64)p / PGSIZE] = 1;
    80000b7e:	00010b17          	auipc	s6,0x10
    80000b82:	3b2b0b13          	addi	s6,s6,946 # 80010f30 <rc>
    80000b86:	4a85                	li	s5,1
    80000b88:	6a05                	lui	s4,0x1
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b8a:	6989                	lui	s3,0x2
    rc[(uint64)p / PGSIZE] = 1;
    80000b8c:	00c4d793          	srli	a5,s1,0xc
    80000b90:	078a                	slli	a5,a5,0x2
    80000b92:	97da                	add	a5,a5,s6
    80000b94:	0157a023          	sw	s5,0(a5)
    kfree(p);
    80000b98:	8526                	mv	a0,s1
    80000b9a:	00000097          	auipc	ra,0x0
    80000b9e:	ee0080e7          	jalr	-288(ra) # 80000a7a <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ba2:	87a6                	mv	a5,s1
    80000ba4:	94d2                	add	s1,s1,s4
    80000ba6:	97ce                	add	a5,a5,s3
    80000ba8:	fef972e3          	bgeu	s2,a5,80000b8c <freerange+0x36>
}
    80000bac:	70e2                	ld	ra,56(sp)
    80000bae:	7442                	ld	s0,48(sp)
    80000bb0:	74a2                	ld	s1,40(sp)
    80000bb2:	7902                	ld	s2,32(sp)
    80000bb4:	69e2                	ld	s3,24(sp)
    80000bb6:	6a42                	ld	s4,16(sp)
    80000bb8:	6aa2                	ld	s5,8(sp)
    80000bba:	6b02                	ld	s6,0(sp)
    80000bbc:	6121                	addi	sp,sp,64
    80000bbe:	8082                	ret

0000000080000bc0 <kinit>:
{
    80000bc0:	1141                	addi	sp,sp,-16
    80000bc2:	e406                	sd	ra,8(sp)
    80000bc4:	e022                	sd	s0,0(sp)
    80000bc6:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000bc8:	00007597          	auipc	a1,0x7
    80000bcc:	4b858593          	addi	a1,a1,1208 # 80008080 <digits+0x40>
    80000bd0:	00010517          	auipc	a0,0x10
    80000bd4:	34050513          	addi	a0,a0,832 # 80010f10 <kmem>
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	0c2080e7          	jalr	194(ra) # 80000c9a <initlock>
  freerange(end, (void *)PHYSTOP);
    80000be0:	45c5                	li	a1,17
    80000be2:	05ee                	slli	a1,a1,0x1b
    80000be4:	00244517          	auipc	a0,0x244
    80000be8:	0dc50513          	addi	a0,a0,220 # 80244cc0 <end>
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f6a080e7          	jalr	-150(ra) # 80000b56 <freerange>
}
    80000bf4:	60a2                	ld	ra,8(sp)
    80000bf6:	6402                	ld	s0,0(sp)
    80000bf8:	0141                	addi	sp,sp,16
    80000bfa:	8082                	ret

0000000080000bfc <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c06:	00010497          	auipc	s1,0x10
    80000c0a:	30a48493          	addi	s1,s1,778 # 80010f10 <kmem>
    80000c0e:	8526                	mv	a0,s1
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	11a080e7          	jalr	282(ra) # 80000d2a <acquire>
  r = kmem.freelist;
    80000c18:	6c84                	ld	s1,24(s1)
  if (r)
    80000c1a:	c4bd                	beqz	s1,80000c88 <kalloc+0x8c>
  {
    kmem.freelist = r->next;
    80000c1c:	609c                	ld	a5,0(s1)
    80000c1e:	00010717          	auipc	a4,0x10
    80000c22:	30f73523          	sd	a5,778(a4) # 80010f28 <kmem+0x18>
    int pn = (uint64)r / PGSIZE;
    80000c26:	00c4d793          	srli	a5,s1,0xc
    80000c2a:	2781                	sext.w	a5,a5
    if (0 != rc[pn])
    80000c2c:	00279693          	slli	a3,a5,0x2
    80000c30:	00010717          	auipc	a4,0x10
    80000c34:	30070713          	addi	a4,a4,768 # 80010f30 <rc>
    80000c38:	9736                	add	a4,a4,a3
    80000c3a:	4318                	lw	a4,0(a4)
    80000c3c:	ef15                	bnez	a4,80000c78 <kalloc+0x7c>
    {
      panic("kalloc: ref");
    }
    rc[pn] = 1;
    80000c3e:	078a                	slli	a5,a5,0x2
    80000c40:	00010717          	auipc	a4,0x10
    80000c44:	2f070713          	addi	a4,a4,752 # 80010f30 <rc>
    80000c48:	97ba                	add	a5,a5,a4
    80000c4a:	4705                	li	a4,1
    80000c4c:	c398                	sw	a4,0(a5)
  }

  release(&kmem.lock);
    80000c4e:	00010517          	auipc	a0,0x10
    80000c52:	2c250513          	addi	a0,a0,706 # 80010f10 <kmem>
    80000c56:	00000097          	auipc	ra,0x0
    80000c5a:	188080e7          	jalr	392(ra) # 80000dde <release>

  if (r)
    memset((char *)r, 5, PGSIZE); // fill with junk
    80000c5e:	6605                	lui	a2,0x1
    80000c60:	4595                	li	a1,5
    80000c62:	8526                	mv	a0,s1
    80000c64:	00000097          	auipc	ra,0x0
    80000c68:	1c2080e7          	jalr	450(ra) # 80000e26 <memset>
  return (void *)r;
}
    80000c6c:	8526                	mv	a0,s1
    80000c6e:	60e2                	ld	ra,24(sp)
    80000c70:	6442                	ld	s0,16(sp)
    80000c72:	64a2                	ld	s1,8(sp)
    80000c74:	6105                	addi	sp,sp,32
    80000c76:	8082                	ret
      panic("kalloc: ref");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	41050513          	addi	a0,a0,1040 # 80008088 <digits+0x48>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8c4080e7          	jalr	-1852(ra) # 80000544 <panic>
  release(&kmem.lock);
    80000c88:	00010517          	auipc	a0,0x10
    80000c8c:	28850513          	addi	a0,a0,648 # 80010f10 <kmem>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	14e080e7          	jalr	334(ra) # 80000dde <release>
  if (r)
    80000c98:	bfd1                	j	80000c6c <kalloc+0x70>

0000000080000c9a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c9a:	1141                	addi	sp,sp,-16
    80000c9c:	e422                	sd	s0,8(sp)
    80000c9e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ca0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000ca2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000ca6:	00053823          	sd	zero,16(a0)
}
    80000caa:	6422                	ld	s0,8(sp)
    80000cac:	0141                	addi	sp,sp,16
    80000cae:	8082                	ret

0000000080000cb0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cb0:	411c                	lw	a5,0(a0)
    80000cb2:	e399                	bnez	a5,80000cb8 <holding+0x8>
    80000cb4:	4501                	li	a0,0
  return r;
}
    80000cb6:	8082                	ret
{
    80000cb8:	1101                	addi	sp,sp,-32
    80000cba:	ec06                	sd	ra,24(sp)
    80000cbc:	e822                	sd	s0,16(sp)
    80000cbe:	e426                	sd	s1,8(sp)
    80000cc0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cc2:	6904                	ld	s1,16(a0)
    80000cc4:	00001097          	auipc	ra,0x1
    80000cc8:	07e080e7          	jalr	126(ra) # 80001d42 <mycpu>
    80000ccc:	40a48533          	sub	a0,s1,a0
    80000cd0:	00153513          	seqz	a0,a0
}
    80000cd4:	60e2                	ld	ra,24(sp)
    80000cd6:	6442                	ld	s0,16(sp)
    80000cd8:	64a2                	ld	s1,8(sp)
    80000cda:	6105                	addi	sp,sp,32
    80000cdc:	8082                	ret

0000000080000cde <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cde:	1101                	addi	sp,sp,-32
    80000ce0:	ec06                	sd	ra,24(sp)
    80000ce2:	e822                	sd	s0,16(sp)
    80000ce4:	e426                	sd	s1,8(sp)
    80000ce6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce8:	100024f3          	csrr	s1,sstatus
    80000cec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cf0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cf2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cf6:	00001097          	auipc	ra,0x1
    80000cfa:	04c080e7          	jalr	76(ra) # 80001d42 <mycpu>
    80000cfe:	5d3c                	lw	a5,120(a0)
    80000d00:	cf89                	beqz	a5,80000d1a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d02:	00001097          	auipc	ra,0x1
    80000d06:	040080e7          	jalr	64(ra) # 80001d42 <mycpu>
    80000d0a:	5d3c                	lw	a5,120(a0)
    80000d0c:	2785                	addiw	a5,a5,1
    80000d0e:	dd3c                	sw	a5,120(a0)
}
    80000d10:	60e2                	ld	ra,24(sp)
    80000d12:	6442                	ld	s0,16(sp)
    80000d14:	64a2                	ld	s1,8(sp)
    80000d16:	6105                	addi	sp,sp,32
    80000d18:	8082                	ret
    mycpu()->intena = old;
    80000d1a:	00001097          	auipc	ra,0x1
    80000d1e:	028080e7          	jalr	40(ra) # 80001d42 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d22:	8085                	srli	s1,s1,0x1
    80000d24:	8885                	andi	s1,s1,1
    80000d26:	dd64                	sw	s1,124(a0)
    80000d28:	bfe9                	j	80000d02 <push_off+0x24>

0000000080000d2a <acquire>:
{
    80000d2a:	1101                	addi	sp,sp,-32
    80000d2c:	ec06                	sd	ra,24(sp)
    80000d2e:	e822                	sd	s0,16(sp)
    80000d30:	e426                	sd	s1,8(sp)
    80000d32:	1000                	addi	s0,sp,32
    80000d34:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d36:	00000097          	auipc	ra,0x0
    80000d3a:	fa8080e7          	jalr	-88(ra) # 80000cde <push_off>
  if(holding(lk))
    80000d3e:	8526                	mv	a0,s1
    80000d40:	00000097          	auipc	ra,0x0
    80000d44:	f70080e7          	jalr	-144(ra) # 80000cb0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d48:	4705                	li	a4,1
  if(holding(lk))
    80000d4a:	e115                	bnez	a0,80000d6e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d4c:	87ba                	mv	a5,a4
    80000d4e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d52:	2781                	sext.w	a5,a5
    80000d54:	ffe5                	bnez	a5,80000d4c <acquire+0x22>
  __sync_synchronize();
    80000d56:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d5a:	00001097          	auipc	ra,0x1
    80000d5e:	fe8080e7          	jalr	-24(ra) # 80001d42 <mycpu>
    80000d62:	e888                	sd	a0,16(s1)
}
    80000d64:	60e2                	ld	ra,24(sp)
    80000d66:	6442                	ld	s0,16(sp)
    80000d68:	64a2                	ld	s1,8(sp)
    80000d6a:	6105                	addi	sp,sp,32
    80000d6c:	8082                	ret
    panic("acquire");
    80000d6e:	00007517          	auipc	a0,0x7
    80000d72:	32a50513          	addi	a0,a0,810 # 80008098 <digits+0x58>
    80000d76:	fffff097          	auipc	ra,0xfffff
    80000d7a:	7ce080e7          	jalr	1998(ra) # 80000544 <panic>

0000000080000d7e <pop_off>:

void
pop_off(void)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d86:	00001097          	auipc	ra,0x1
    80000d8a:	fbc080e7          	jalr	-68(ra) # 80001d42 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d92:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d94:	e78d                	bnez	a5,80000dbe <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d96:	5d3c                	lw	a5,120(a0)
    80000d98:	02f05b63          	blez	a5,80000dce <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d9c:	37fd                	addiw	a5,a5,-1
    80000d9e:	0007871b          	sext.w	a4,a5
    80000da2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000da4:	eb09                	bnez	a4,80000db6 <pop_off+0x38>
    80000da6:	5d7c                	lw	a5,124(a0)
    80000da8:	c799                	beqz	a5,80000db6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000daa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000dae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000db2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret
    panic("pop_off - interruptible");
    80000dbe:	00007517          	auipc	a0,0x7
    80000dc2:	2e250513          	addi	a0,a0,738 # 800080a0 <digits+0x60>
    80000dc6:	fffff097          	auipc	ra,0xfffff
    80000dca:	77e080e7          	jalr	1918(ra) # 80000544 <panic>
    panic("pop_off");
    80000dce:	00007517          	auipc	a0,0x7
    80000dd2:	2ea50513          	addi	a0,a0,746 # 800080b8 <digits+0x78>
    80000dd6:	fffff097          	auipc	ra,0xfffff
    80000dda:	76e080e7          	jalr	1902(ra) # 80000544 <panic>

0000000080000dde <release>:
{
    80000dde:	1101                	addi	sp,sp,-32
    80000de0:	ec06                	sd	ra,24(sp)
    80000de2:	e822                	sd	s0,16(sp)
    80000de4:	e426                	sd	s1,8(sp)
    80000de6:	1000                	addi	s0,sp,32
    80000de8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dea:	00000097          	auipc	ra,0x0
    80000dee:	ec6080e7          	jalr	-314(ra) # 80000cb0 <holding>
    80000df2:	c115                	beqz	a0,80000e16 <release+0x38>
  lk->cpu = 0;
    80000df4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000df8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dfc:	0f50000f          	fence	iorw,ow
    80000e00:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f7a080e7          	jalr	-134(ra) # 80000d7e <pop_off>
}
    80000e0c:	60e2                	ld	ra,24(sp)
    80000e0e:	6442                	ld	s0,16(sp)
    80000e10:	64a2                	ld	s1,8(sp)
    80000e12:	6105                	addi	sp,sp,32
    80000e14:	8082                	ret
    panic("release");
    80000e16:	00007517          	auipc	a0,0x7
    80000e1a:	2aa50513          	addi	a0,a0,682 # 800080c0 <digits+0x80>
    80000e1e:	fffff097          	auipc	ra,0xfffff
    80000e22:	726080e7          	jalr	1830(ra) # 80000544 <panic>

0000000080000e26 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e26:	1141                	addi	sp,sp,-16
    80000e28:	e422                	sd	s0,8(sp)
    80000e2a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e2c:	ce09                	beqz	a2,80000e46 <memset+0x20>
    80000e2e:	87aa                	mv	a5,a0
    80000e30:	fff6071b          	addiw	a4,a2,-1
    80000e34:	1702                	slli	a4,a4,0x20
    80000e36:	9301                	srli	a4,a4,0x20
    80000e38:	0705                	addi	a4,a4,1
    80000e3a:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e3c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e40:	0785                	addi	a5,a5,1
    80000e42:	fee79de3          	bne	a5,a4,80000e3c <memset+0x16>
  }
  return dst;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e52:	ca05                	beqz	a2,80000e82 <memcmp+0x36>
    80000e54:	fff6069b          	addiw	a3,a2,-1
    80000e58:	1682                	slli	a3,a3,0x20
    80000e5a:	9281                	srli	a3,a3,0x20
    80000e5c:	0685                	addi	a3,a3,1
    80000e5e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	0005c703          	lbu	a4,0(a1)
    80000e68:	00e79863          	bne	a5,a4,80000e78 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e6c:	0505                	addi	a0,a0,1
    80000e6e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e70:	fed518e3          	bne	a0,a3,80000e60 <memcmp+0x14>
  }

  return 0;
    80000e74:	4501                	li	a0,0
    80000e76:	a019                	j	80000e7c <memcmp+0x30>
      return *s1 - *s2;
    80000e78:	40e7853b          	subw	a0,a5,a4
}
    80000e7c:	6422                	ld	s0,8(sp)
    80000e7e:	0141                	addi	sp,sp,16
    80000e80:	8082                	ret
  return 0;
    80000e82:	4501                	li	a0,0
    80000e84:	bfe5                	j	80000e7c <memcmp+0x30>

0000000080000e86 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e86:	1141                	addi	sp,sp,-16
    80000e88:	e422                	sd	s0,8(sp)
    80000e8a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e8c:	ca0d                	beqz	a2,80000ebe <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e8e:	00a5f963          	bgeu	a1,a0,80000ea0 <memmove+0x1a>
    80000e92:	02061693          	slli	a3,a2,0x20
    80000e96:	9281                	srli	a3,a3,0x20
    80000e98:	00d58733          	add	a4,a1,a3
    80000e9c:	02e56463          	bltu	a0,a4,80000ec4 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ea0:	fff6079b          	addiw	a5,a2,-1
    80000ea4:	1782                	slli	a5,a5,0x20
    80000ea6:	9381                	srli	a5,a5,0x20
    80000ea8:	0785                	addi	a5,a5,1
    80000eaa:	97ae                	add	a5,a5,a1
    80000eac:	872a                	mv	a4,a0
      *d++ = *s++;
    80000eae:	0585                	addi	a1,a1,1
    80000eb0:	0705                	addi	a4,a4,1
    80000eb2:	fff5c683          	lbu	a3,-1(a1)
    80000eb6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000eba:	fef59ae3          	bne	a1,a5,80000eae <memmove+0x28>

  return dst;
}
    80000ebe:	6422                	ld	s0,8(sp)
    80000ec0:	0141                	addi	sp,sp,16
    80000ec2:	8082                	ret
    d += n;
    80000ec4:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ec6:	fff6079b          	addiw	a5,a2,-1
    80000eca:	1782                	slli	a5,a5,0x20
    80000ecc:	9381                	srli	a5,a5,0x20
    80000ece:	fff7c793          	not	a5,a5
    80000ed2:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ed4:	177d                	addi	a4,a4,-1
    80000ed6:	16fd                	addi	a3,a3,-1
    80000ed8:	00074603          	lbu	a2,0(a4)
    80000edc:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000ee0:	fef71ae3          	bne	a4,a5,80000ed4 <memmove+0x4e>
    80000ee4:	bfe9                	j	80000ebe <memmove+0x38>

0000000080000ee6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ee6:	1141                	addi	sp,sp,-16
    80000ee8:	e406                	sd	ra,8(sp)
    80000eea:	e022                	sd	s0,0(sp)
    80000eec:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000eee:	00000097          	auipc	ra,0x0
    80000ef2:	f98080e7          	jalr	-104(ra) # 80000e86 <memmove>
}
    80000ef6:	60a2                	ld	ra,8(sp)
    80000ef8:	6402                	ld	s0,0(sp)
    80000efa:	0141                	addi	sp,sp,16
    80000efc:	8082                	ret

0000000080000efe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000efe:	1141                	addi	sp,sp,-16
    80000f00:	e422                	sd	s0,8(sp)
    80000f02:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f04:	ce11                	beqz	a2,80000f20 <strncmp+0x22>
    80000f06:	00054783          	lbu	a5,0(a0)
    80000f0a:	cf89                	beqz	a5,80000f24 <strncmp+0x26>
    80000f0c:	0005c703          	lbu	a4,0(a1)
    80000f10:	00f71a63          	bne	a4,a5,80000f24 <strncmp+0x26>
    n--, p++, q++;
    80000f14:	367d                	addiw	a2,a2,-1
    80000f16:	0505                	addi	a0,a0,1
    80000f18:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f1a:	f675                	bnez	a2,80000f06 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f1c:	4501                	li	a0,0
    80000f1e:	a809                	j	80000f30 <strncmp+0x32>
    80000f20:	4501                	li	a0,0
    80000f22:	a039                	j	80000f30 <strncmp+0x32>
  if(n == 0)
    80000f24:	ca09                	beqz	a2,80000f36 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f26:	00054503          	lbu	a0,0(a0)
    80000f2a:	0005c783          	lbu	a5,0(a1)
    80000f2e:	9d1d                	subw	a0,a0,a5
}
    80000f30:	6422                	ld	s0,8(sp)
    80000f32:	0141                	addi	sp,sp,16
    80000f34:	8082                	ret
    return 0;
    80000f36:	4501                	li	a0,0
    80000f38:	bfe5                	j	80000f30 <strncmp+0x32>

0000000080000f3a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f3a:	1141                	addi	sp,sp,-16
    80000f3c:	e422                	sd	s0,8(sp)
    80000f3e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f40:	872a                	mv	a4,a0
    80000f42:	8832                	mv	a6,a2
    80000f44:	367d                	addiw	a2,a2,-1
    80000f46:	01005963          	blez	a6,80000f58 <strncpy+0x1e>
    80000f4a:	0705                	addi	a4,a4,1
    80000f4c:	0005c783          	lbu	a5,0(a1)
    80000f50:	fef70fa3          	sb	a5,-1(a4)
    80000f54:	0585                	addi	a1,a1,1
    80000f56:	f7f5                	bnez	a5,80000f42 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f58:	00c05d63          	blez	a2,80000f72 <strncpy+0x38>
    80000f5c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f5e:	0685                	addi	a3,a3,1
    80000f60:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f64:	fff6c793          	not	a5,a3
    80000f68:	9fb9                	addw	a5,a5,a4
    80000f6a:	010787bb          	addw	a5,a5,a6
    80000f6e:	fef048e3          	bgtz	a5,80000f5e <strncpy+0x24>
  return os;
}
    80000f72:	6422                	ld	s0,8(sp)
    80000f74:	0141                	addi	sp,sp,16
    80000f76:	8082                	ret

0000000080000f78 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f78:	1141                	addi	sp,sp,-16
    80000f7a:	e422                	sd	s0,8(sp)
    80000f7c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f7e:	02c05363          	blez	a2,80000fa4 <safestrcpy+0x2c>
    80000f82:	fff6069b          	addiw	a3,a2,-1
    80000f86:	1682                	slli	a3,a3,0x20
    80000f88:	9281                	srli	a3,a3,0x20
    80000f8a:	96ae                	add	a3,a3,a1
    80000f8c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f8e:	00d58963          	beq	a1,a3,80000fa0 <safestrcpy+0x28>
    80000f92:	0585                	addi	a1,a1,1
    80000f94:	0785                	addi	a5,a5,1
    80000f96:	fff5c703          	lbu	a4,-1(a1)
    80000f9a:	fee78fa3          	sb	a4,-1(a5)
    80000f9e:	fb65                	bnez	a4,80000f8e <safestrcpy+0x16>
    ;
  *s = 0;
    80000fa0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fa4:	6422                	ld	s0,8(sp)
    80000fa6:	0141                	addi	sp,sp,16
    80000fa8:	8082                	ret

0000000080000faa <strlen>:

int
strlen(const char *s)
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fb0:	00054783          	lbu	a5,0(a0)
    80000fb4:	cf91                	beqz	a5,80000fd0 <strlen+0x26>
    80000fb6:	0505                	addi	a0,a0,1
    80000fb8:	87aa                	mv	a5,a0
    80000fba:	4685                	li	a3,1
    80000fbc:	9e89                	subw	a3,a3,a0
    80000fbe:	00f6853b          	addw	a0,a3,a5
    80000fc2:	0785                	addi	a5,a5,1
    80000fc4:	fff7c703          	lbu	a4,-1(a5)
    80000fc8:	fb7d                	bnez	a4,80000fbe <strlen+0x14>
    ;
  return n;
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fd0:	4501                	li	a0,0
    80000fd2:	bfe5                	j	80000fca <strlen+0x20>

0000000080000fd4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e406                	sd	ra,8(sp)
    80000fd8:	e022                	sd	s0,0(sp)
    80000fda:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fdc:	00001097          	auipc	ra,0x1
    80000fe0:	d56080e7          	jalr	-682(ra) # 80001d32 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fe4:	00008717          	auipc	a4,0x8
    80000fe8:	cc470713          	addi	a4,a4,-828 # 80008ca8 <started>
  if(cpuid() == 0){
    80000fec:	c139                	beqz	a0,80001032 <main+0x5e>
    while(started == 0)
    80000fee:	431c                	lw	a5,0(a4)
    80000ff0:	2781                	sext.w	a5,a5
    80000ff2:	dff5                	beqz	a5,80000fee <main+0x1a>
      ;
    __sync_synchronize();
    80000ff4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ff8:	00001097          	auipc	ra,0x1
    80000ffc:	d3a080e7          	jalr	-710(ra) # 80001d32 <cpuid>
    80001000:	85aa                	mv	a1,a0
    80001002:	00007517          	auipc	a0,0x7
    80001006:	0de50513          	addi	a0,a0,222 # 800080e0 <digits+0xa0>
    8000100a:	fffff097          	auipc	ra,0xfffff
    8000100e:	584080e7          	jalr	1412(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80001012:	00000097          	auipc	ra,0x0
    80001016:	0d8080e7          	jalr	216(ra) # 800010ea <kvminithart>
    trapinithart();   // install kernel trap vector
    8000101a:	00002097          	auipc	ra,0x2
    8000101e:	dcc080e7          	jalr	-564(ra) # 80002de6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001022:	00005097          	auipc	ra,0x5
    80001026:	6ee080e7          	jalr	1774(ra) # 80006710 <plicinithart>
  }

  scheduler();        
    8000102a:	00001097          	auipc	ra,0x1
    8000102e:	44e080e7          	jalr	1102(ra) # 80002478 <scheduler>
    consoleinit();
    80001032:	fffff097          	auipc	ra,0xfffff
    80001036:	424080e7          	jalr	1060(ra) # 80000456 <consoleinit>
    printfinit();
    8000103a:	fffff097          	auipc	ra,0xfffff
    8000103e:	73a080e7          	jalr	1850(ra) # 80000774 <printfinit>
    printf("\n");
    80001042:	00007517          	auipc	a0,0x7
    80001046:	4fe50513          	addi	a0,a0,1278 # 80008540 <states.1862+0x1a8>
    8000104a:	fffff097          	auipc	ra,0xfffff
    8000104e:	544080e7          	jalr	1348(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80001052:	00007517          	auipc	a0,0x7
    80001056:	07650513          	addi	a0,a0,118 # 800080c8 <digits+0x88>
    8000105a:	fffff097          	auipc	ra,0xfffff
    8000105e:	534080e7          	jalr	1332(ra) # 8000058e <printf>
    printf("\n");
    80001062:	00007517          	auipc	a0,0x7
    80001066:	4de50513          	addi	a0,a0,1246 # 80008540 <states.1862+0x1a8>
    8000106a:	fffff097          	auipc	ra,0xfffff
    8000106e:	524080e7          	jalr	1316(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80001072:	00000097          	auipc	ra,0x0
    80001076:	b4e080e7          	jalr	-1202(ra) # 80000bc0 <kinit>
    kvminit();       // create kernel page table
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	326080e7          	jalr	806(ra) # 800013a0 <kvminit>
    kvminithart();   // turn on paging
    80001082:	00000097          	auipc	ra,0x0
    80001086:	068080e7          	jalr	104(ra) # 800010ea <kvminithart>
    procinit();      // process table
    8000108a:	00001097          	auipc	ra,0x1
    8000108e:	bf4080e7          	jalr	-1036(ra) # 80001c7e <procinit>
    trapinit();      // trap vectors
    80001092:	00002097          	auipc	ra,0x2
    80001096:	d2c080e7          	jalr	-724(ra) # 80002dbe <trapinit>
    trapinithart();  // install kernel trap vector
    8000109a:	00002097          	auipc	ra,0x2
    8000109e:	d4c080e7          	jalr	-692(ra) # 80002de6 <trapinithart>
    plicinit();      // set up interrupt controller
    800010a2:	00005097          	auipc	ra,0x5
    800010a6:	658080e7          	jalr	1624(ra) # 800066fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010aa:	00005097          	auipc	ra,0x5
    800010ae:	666080e7          	jalr	1638(ra) # 80006710 <plicinithart>
    binit();         // buffer cache
    800010b2:	00003097          	auipc	ra,0x3
    800010b6:	81e080e7          	jalr	-2018(ra) # 800038d0 <binit>
    iinit();         // inode table
    800010ba:	00003097          	auipc	ra,0x3
    800010be:	ec2080e7          	jalr	-318(ra) # 80003f7c <iinit>
    fileinit();      // file table
    800010c2:	00004097          	auipc	ra,0x4
    800010c6:	e60080e7          	jalr	-416(ra) # 80004f22 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010ca:	00005097          	auipc	ra,0x5
    800010ce:	74e080e7          	jalr	1870(ra) # 80006818 <virtio_disk_init>
    userinit();      // first user process
    800010d2:	00001097          	auipc	ra,0x1
    800010d6:	102080e7          	jalr	258(ra) # 800021d4 <userinit>
    __sync_synchronize();
    800010da:	0ff0000f          	fence
    started = 1;
    800010de:	4785                	li	a5,1
    800010e0:	00008717          	auipc	a4,0x8
    800010e4:	bcf72423          	sw	a5,-1080(a4) # 80008ca8 <started>
    800010e8:	b789                	j	8000102a <main+0x56>

00000000800010ea <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    800010ea:	1141                	addi	sp,sp,-16
    800010ec:	e422                	sd	s0,8(sp)
    800010ee:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010f0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010f4:	00008797          	auipc	a5,0x8
    800010f8:	bbc7b783          	ld	a5,-1092(a5) # 80008cb0 <kernel_pagetable>
    800010fc:	83b1                	srli	a5,a5,0xc
    800010fe:	577d                	li	a4,-1
    80001100:	177e                	slli	a4,a4,0x3f
    80001102:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001104:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001108:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000110c:	6422                	ld	s0,8(sp)
    8000110e:	0141                	addi	sp,sp,16
    80001110:	8082                	ret

0000000080001112 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001112:	7139                	addi	sp,sp,-64
    80001114:	fc06                	sd	ra,56(sp)
    80001116:	f822                	sd	s0,48(sp)
    80001118:	f426                	sd	s1,40(sp)
    8000111a:	f04a                	sd	s2,32(sp)
    8000111c:	ec4e                	sd	s3,24(sp)
    8000111e:	e852                	sd	s4,16(sp)
    80001120:	e456                	sd	s5,8(sp)
    80001122:	e05a                	sd	s6,0(sp)
    80001124:	0080                	addi	s0,sp,64
    80001126:	84aa                	mv	s1,a0
    80001128:	89ae                	mv	s3,a1
    8000112a:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    8000112c:	57fd                	li	a5,-1
    8000112e:	83e9                	srli	a5,a5,0x1a
    80001130:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    80001132:	4b31                	li	s6,12
  if (va >= MAXVA)
    80001134:	04b7f263          	bgeu	a5,a1,80001178 <walk+0x66>
    panic("walk");
    80001138:	00007517          	auipc	a0,0x7
    8000113c:	fc050513          	addi	a0,a0,-64 # 800080f8 <digits+0xb8>
    80001140:	fffff097          	auipc	ra,0xfffff
    80001144:	404080e7          	jalr	1028(ra) # 80000544 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001148:	060a8663          	beqz	s5,800011b4 <walk+0xa2>
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	ab0080e7          	jalr	-1360(ra) # 80000bfc <kalloc>
    80001154:	84aa                	mv	s1,a0
    80001156:	c529                	beqz	a0,800011a0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001158:	6605                	lui	a2,0x1
    8000115a:	4581                	li	a1,0
    8000115c:	00000097          	auipc	ra,0x0
    80001160:	cca080e7          	jalr	-822(ra) # 80000e26 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001164:	00c4d793          	srli	a5,s1,0xc
    80001168:	07aa                	slli	a5,a5,0xa
    8000116a:	0017e793          	ori	a5,a5,1
    8000116e:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    80001172:	3a5d                	addiw	s4,s4,-9
    80001174:	036a0063          	beq	s4,s6,80001194 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001178:	0149d933          	srl	s2,s3,s4
    8000117c:	1ff97913          	andi	s2,s2,511
    80001180:	090e                	slli	s2,s2,0x3
    80001182:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    80001184:	00093483          	ld	s1,0(s2)
    80001188:	0014f793          	andi	a5,s1,1
    8000118c:	dfd5                	beqz	a5,80001148 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000118e:	80a9                	srli	s1,s1,0xa
    80001190:	04b2                	slli	s1,s1,0xc
    80001192:	b7c5                	j	80001172 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001194:	00c9d513          	srli	a0,s3,0xc
    80001198:	1ff57513          	andi	a0,a0,511
    8000119c:	050e                	slli	a0,a0,0x3
    8000119e:	9526                	add	a0,a0,s1
}
    800011a0:	70e2                	ld	ra,56(sp)
    800011a2:	7442                	ld	s0,48(sp)
    800011a4:	74a2                	ld	s1,40(sp)
    800011a6:	7902                	ld	s2,32(sp)
    800011a8:	69e2                	ld	s3,24(sp)
    800011aa:	6a42                	ld	s4,16(sp)
    800011ac:	6aa2                	ld	s5,8(sp)
    800011ae:	6b02                	ld	s6,0(sp)
    800011b0:	6121                	addi	sp,sp,64
    800011b2:	8082                	ret
        return 0;
    800011b4:	4501                	li	a0,0
    800011b6:	b7ed                	j	800011a0 <walk+0x8e>

00000000800011b8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    800011b8:	57fd                	li	a5,-1
    800011ba:	83e9                	srli	a5,a5,0x1a
    800011bc:	00b7f463          	bgeu	a5,a1,800011c4 <walkaddr+0xc>
    return 0;
    800011c0:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011c2:	8082                	ret
{
    800011c4:	1141                	addi	sp,sp,-16
    800011c6:	e406                	sd	ra,8(sp)
    800011c8:	e022                	sd	s0,0(sp)
    800011ca:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011cc:	4601                	li	a2,0
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f44080e7          	jalr	-188(ra) # 80001112 <walk>
  if (pte == 0)
    800011d6:	c105                	beqz	a0,800011f6 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    800011d8:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    800011da:	0117f693          	andi	a3,a5,17
    800011de:	4745                	li	a4,17
    return 0;
    800011e0:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    800011e2:	00e68663          	beq	a3,a4,800011ee <walkaddr+0x36>
}
    800011e6:	60a2                	ld	ra,8(sp)
    800011e8:	6402                	ld	s0,0(sp)
    800011ea:	0141                	addi	sp,sp,16
    800011ec:	8082                	ret
  pa = PTE2PA(*pte);
    800011ee:	00a7d513          	srli	a0,a5,0xa
    800011f2:	0532                	slli	a0,a0,0xc
  return pa;
    800011f4:	bfcd                	j	800011e6 <walkaddr+0x2e>
    return 0;
    800011f6:	4501                	li	a0,0
    800011f8:	b7fd                	j	800011e6 <walkaddr+0x2e>

00000000800011fa <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011fa:	715d                	addi	sp,sp,-80
    800011fc:	e486                	sd	ra,72(sp)
    800011fe:	e0a2                	sd	s0,64(sp)
    80001200:	fc26                	sd	s1,56(sp)
    80001202:	f84a                	sd	s2,48(sp)
    80001204:	f44e                	sd	s3,40(sp)
    80001206:	f052                	sd	s4,32(sp)
    80001208:	ec56                	sd	s5,24(sp)
    8000120a:	e85a                	sd	s6,16(sp)
    8000120c:	e45e                	sd	s7,8(sp)
    8000120e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    80001210:	c205                	beqz	a2,80001230 <mappages+0x36>
    80001212:	8aaa                	mv	s5,a0
    80001214:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001216:	77fd                	lui	a5,0xfffff
    80001218:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000121c:	15fd                	addi	a1,a1,-1
    8000121e:	00c589b3          	add	s3,a1,a2
    80001222:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001226:	8952                	mv	s2,s4
    80001228:	41468a33          	sub	s4,a3,s4
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    8000122c:	6b85                	lui	s7,0x1
    8000122e:	a015                	j	80001252 <mappages+0x58>
    panic("mappages: size");
    80001230:	00007517          	auipc	a0,0x7
    80001234:	ed050513          	addi	a0,a0,-304 # 80008100 <digits+0xc0>
    80001238:	fffff097          	auipc	ra,0xfffff
    8000123c:	30c080e7          	jalr	780(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001240:	00007517          	auipc	a0,0x7
    80001244:	ed050513          	addi	a0,a0,-304 # 80008110 <digits+0xd0>
    80001248:	fffff097          	auipc	ra,0xfffff
    8000124c:	2fc080e7          	jalr	764(ra) # 80000544 <panic>
    a += PGSIZE;
    80001250:	995e                	add	s2,s2,s7
  for (;;)
    80001252:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001256:	4605                	li	a2,1
    80001258:	85ca                	mv	a1,s2
    8000125a:	8556                	mv	a0,s5
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	eb6080e7          	jalr	-330(ra) # 80001112 <walk>
    80001264:	cd19                	beqz	a0,80001282 <mappages+0x88>
    if (*pte & PTE_V)
    80001266:	611c                	ld	a5,0(a0)
    80001268:	8b85                	andi	a5,a5,1
    8000126a:	fbf9                	bnez	a5,80001240 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000126c:	80b1                	srli	s1,s1,0xc
    8000126e:	04aa                	slli	s1,s1,0xa
    80001270:	0164e4b3          	or	s1,s1,s6
    80001274:	0014e493          	ori	s1,s1,1
    80001278:	e104                	sd	s1,0(a0)
    if (a == last)
    8000127a:	fd391be3          	bne	s2,s3,80001250 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000127e:	4501                	li	a0,0
    80001280:	a011                	j	80001284 <mappages+0x8a>
      return -1;
    80001282:	557d                	li	a0,-1
}
    80001284:	60a6                	ld	ra,72(sp)
    80001286:	6406                	ld	s0,64(sp)
    80001288:	74e2                	ld	s1,56(sp)
    8000128a:	7942                	ld	s2,48(sp)
    8000128c:	79a2                	ld	s3,40(sp)
    8000128e:	7a02                	ld	s4,32(sp)
    80001290:	6ae2                	ld	s5,24(sp)
    80001292:	6b42                	ld	s6,16(sp)
    80001294:	6ba2                	ld	s7,8(sp)
    80001296:	6161                	addi	sp,sp,80
    80001298:	8082                	ret

000000008000129a <kvmmap>:
{
    8000129a:	1141                	addi	sp,sp,-16
    8000129c:	e406                	sd	ra,8(sp)
    8000129e:	e022                	sd	s0,0(sp)
    800012a0:	0800                	addi	s0,sp,16
    800012a2:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012a4:	86b2                	mv	a3,a2
    800012a6:	863e                	mv	a2,a5
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f52080e7          	jalr	-174(ra) # 800011fa <mappages>
    800012b0:	e509                	bnez	a0,800012ba <kvmmap+0x20>
}
    800012b2:	60a2                	ld	ra,8(sp)
    800012b4:	6402                	ld	s0,0(sp)
    800012b6:	0141                	addi	sp,sp,16
    800012b8:	8082                	ret
    panic("kvmmap");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e6650513          	addi	a0,a0,-410 # 80008120 <digits+0xe0>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	282080e7          	jalr	642(ra) # 80000544 <panic>

00000000800012ca <kvmmake>:
{
    800012ca:	1101                	addi	sp,sp,-32
    800012cc:	ec06                	sd	ra,24(sp)
    800012ce:	e822                	sd	s0,16(sp)
    800012d0:	e426                	sd	s1,8(sp)
    800012d2:	e04a                	sd	s2,0(sp)
    800012d4:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	926080e7          	jalr	-1754(ra) # 80000bfc <kalloc>
    800012de:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012e0:	6605                	lui	a2,0x1
    800012e2:	4581                	li	a1,0
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	b42080e7          	jalr	-1214(ra) # 80000e26 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012ec:	4719                	li	a4,6
    800012ee:	6685                	lui	a3,0x1
    800012f0:	10000637          	lui	a2,0x10000
    800012f4:	100005b7          	lui	a1,0x10000
    800012f8:	8526                	mv	a0,s1
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	fa0080e7          	jalr	-96(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001302:	4719                	li	a4,6
    80001304:	6685                	lui	a3,0x1
    80001306:	10001637          	lui	a2,0x10001
    8000130a:	100015b7          	lui	a1,0x10001
    8000130e:	8526                	mv	a0,s1
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f8a080e7          	jalr	-118(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001318:	4719                	li	a4,6
    8000131a:	004006b7          	lui	a3,0x400
    8000131e:	0c000637          	lui	a2,0xc000
    80001322:	0c0005b7          	lui	a1,0xc000
    80001326:	8526                	mv	a0,s1
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	f72080e7          	jalr	-142(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    80001330:	00007917          	auipc	s2,0x7
    80001334:	cd090913          	addi	s2,s2,-816 # 80008000 <etext>
    80001338:	4729                	li	a4,10
    8000133a:	80007697          	auipc	a3,0x80007
    8000133e:	cc668693          	addi	a3,a3,-826 # 8000 <_entry-0x7fff8000>
    80001342:	4605                	li	a2,1
    80001344:	067e                	slli	a2,a2,0x1f
    80001346:	85b2                	mv	a1,a2
    80001348:	8526                	mv	a0,s1
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	f50080e7          	jalr	-176(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    80001352:	4719                	li	a4,6
    80001354:	46c5                	li	a3,17
    80001356:	06ee                	slli	a3,a3,0x1b
    80001358:	412686b3          	sub	a3,a3,s2
    8000135c:	864a                	mv	a2,s2
    8000135e:	85ca                	mv	a1,s2
    80001360:	8526                	mv	a0,s1
    80001362:	00000097          	auipc	ra,0x0
    80001366:	f38080e7          	jalr	-200(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000136a:	4729                	li	a4,10
    8000136c:	6685                	lui	a3,0x1
    8000136e:	00006617          	auipc	a2,0x6
    80001372:	c9260613          	addi	a2,a2,-878 # 80007000 <_trampoline>
    80001376:	040005b7          	lui	a1,0x4000
    8000137a:	15fd                	addi	a1,a1,-1
    8000137c:	05b2                	slli	a1,a1,0xc
    8000137e:	8526                	mv	a0,s1
    80001380:	00000097          	auipc	ra,0x0
    80001384:	f1a080e7          	jalr	-230(ra) # 8000129a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001388:	8526                	mv	a0,s1
    8000138a:	00001097          	auipc	ra,0x1
    8000138e:	85e080e7          	jalr	-1954(ra) # 80001be8 <proc_mapstacks>
}
    80001392:	8526                	mv	a0,s1
    80001394:	60e2                	ld	ra,24(sp)
    80001396:	6442                	ld	s0,16(sp)
    80001398:	64a2                	ld	s1,8(sp)
    8000139a:	6902                	ld	s2,0(sp)
    8000139c:	6105                	addi	sp,sp,32
    8000139e:	8082                	ret

00000000800013a0 <kvminit>:
{
    800013a0:	1141                	addi	sp,sp,-16
    800013a2:	e406                	sd	ra,8(sp)
    800013a4:	e022                	sd	s0,0(sp)
    800013a6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	f22080e7          	jalr	-222(ra) # 800012ca <kvmmake>
    800013b0:	00008797          	auipc	a5,0x8
    800013b4:	90a7b023          	sd	a0,-1792(a5) # 80008cb0 <kernel_pagetable>
}
    800013b8:	60a2                	ld	ra,8(sp)
    800013ba:	6402                	ld	s0,0(sp)
    800013bc:	0141                	addi	sp,sp,16
    800013be:	8082                	ret

00000000800013c0 <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013c0:	715d                	addi	sp,sp,-80
    800013c2:	e486                	sd	ra,72(sp)
    800013c4:	e0a2                	sd	s0,64(sp)
    800013c6:	fc26                	sd	s1,56(sp)
    800013c8:	f84a                	sd	s2,48(sp)
    800013ca:	f44e                	sd	s3,40(sp)
    800013cc:	f052                	sd	s4,32(sp)
    800013ce:	ec56                	sd	s5,24(sp)
    800013d0:	e85a                	sd	s6,16(sp)
    800013d2:	e45e                	sd	s7,8(sp)
    800013d4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    800013d6:	03459793          	slli	a5,a1,0x34
    800013da:	e795                	bnez	a5,80001406 <uvmunmap+0x46>
    800013dc:	8a2a                	mv	s4,a0
    800013de:	892e                	mv	s2,a1
    800013e0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800013e2:	0632                	slli	a2,a2,0xc
    800013e4:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    800013e8:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800013ea:	6b05                	lui	s6,0x1
    800013ec:	0735e863          	bltu	a1,s3,8000145c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    800013f0:	60a6                	ld	ra,72(sp)
    800013f2:	6406                	ld	s0,64(sp)
    800013f4:	74e2                	ld	s1,56(sp)
    800013f6:	7942                	ld	s2,48(sp)
    800013f8:	79a2                	ld	s3,40(sp)
    800013fa:	7a02                	ld	s4,32(sp)
    800013fc:	6ae2                	ld	s5,24(sp)
    800013fe:	6b42                	ld	s6,16(sp)
    80001400:	6ba2                	ld	s7,8(sp)
    80001402:	6161                	addi	sp,sp,80
    80001404:	8082                	ret
    panic("uvmunmap: not aligned");
    80001406:	00007517          	auipc	a0,0x7
    8000140a:	d2250513          	addi	a0,a0,-734 # 80008128 <digits+0xe8>
    8000140e:	fffff097          	auipc	ra,0xfffff
    80001412:	136080e7          	jalr	310(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    80001416:	00007517          	auipc	a0,0x7
    8000141a:	d2a50513          	addi	a0,a0,-726 # 80008140 <digits+0x100>
    8000141e:	fffff097          	auipc	ra,0xfffff
    80001422:	126080e7          	jalr	294(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    80001426:	00007517          	auipc	a0,0x7
    8000142a:	d2a50513          	addi	a0,a0,-726 # 80008150 <digits+0x110>
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	116080e7          	jalr	278(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    80001436:	00007517          	auipc	a0,0x7
    8000143a:	d3250513          	addi	a0,a0,-718 # 80008168 <digits+0x128>
    8000143e:	fffff097          	auipc	ra,0xfffff
    80001442:	106080e7          	jalr	262(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001446:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    80001448:	0532                	slli	a0,a0,0xc
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	630080e7          	jalr	1584(ra) # 80000a7a <kfree>
    *pte = 0;
    80001452:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001456:	995a                	add	s2,s2,s6
    80001458:	f9397ce3          	bgeu	s2,s3,800013f0 <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    8000145c:	4601                	li	a2,0
    8000145e:	85ca                	mv	a1,s2
    80001460:	8552                	mv	a0,s4
    80001462:	00000097          	auipc	ra,0x0
    80001466:	cb0080e7          	jalr	-848(ra) # 80001112 <walk>
    8000146a:	84aa                	mv	s1,a0
    8000146c:	d54d                	beqz	a0,80001416 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    8000146e:	6108                	ld	a0,0(a0)
    80001470:	00157793          	andi	a5,a0,1
    80001474:	dbcd                	beqz	a5,80001426 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    80001476:	3ff57793          	andi	a5,a0,1023
    8000147a:	fb778ee3          	beq	a5,s7,80001436 <uvmunmap+0x76>
    if (do_free)
    8000147e:	fc0a8ae3          	beqz	s5,80001452 <uvmunmap+0x92>
    80001482:	b7d1                	j	80001446 <uvmunmap+0x86>

0000000080001484 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001484:	1101                	addi	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	76e080e7          	jalr	1902(ra) # 80000bfc <kalloc>
    80001496:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001498:	c519                	beqz	a0,800014a6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000149a:	6605                	lui	a2,0x1
    8000149c:	4581                	li	a1,0
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	988080e7          	jalr	-1656(ra) # 80000e26 <memset>
  return pagetable;
}
    800014a6:	8526                	mv	a0,s1
    800014a8:	60e2                	ld	ra,24(sp)
    800014aa:	6442                	ld	s0,16(sp)
    800014ac:	64a2                	ld	s1,8(sp)
    800014ae:	6105                	addi	sp,sp,32
    800014b0:	8082                	ret

00000000800014b2 <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014b2:	7179                	addi	sp,sp,-48
    800014b4:	f406                	sd	ra,40(sp)
    800014b6:	f022                	sd	s0,32(sp)
    800014b8:	ec26                	sd	s1,24(sp)
    800014ba:	e84a                	sd	s2,16(sp)
    800014bc:	e44e                	sd	s3,8(sp)
    800014be:	e052                	sd	s4,0(sp)
    800014c0:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    800014c2:	6785                	lui	a5,0x1
    800014c4:	04f67863          	bgeu	a2,a5,80001514 <uvmfirst+0x62>
    800014c8:	8a2a                	mv	s4,a0
    800014ca:	89ae                	mv	s3,a1
    800014cc:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	72e080e7          	jalr	1838(ra) # 80000bfc <kalloc>
    800014d6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014d8:	6605                	lui	a2,0x1
    800014da:	4581                	li	a1,0
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	94a080e7          	jalr	-1718(ra) # 80000e26 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    800014e4:	4779                	li	a4,30
    800014e6:	86ca                	mv	a3,s2
    800014e8:	6605                	lui	a2,0x1
    800014ea:	4581                	li	a1,0
    800014ec:	8552                	mv	a0,s4
    800014ee:	00000097          	auipc	ra,0x0
    800014f2:	d0c080e7          	jalr	-756(ra) # 800011fa <mappages>
  memmove(mem, src, sz);
    800014f6:	8626                	mv	a2,s1
    800014f8:	85ce                	mv	a1,s3
    800014fa:	854a                	mv	a0,s2
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	98a080e7          	jalr	-1654(ra) # 80000e86 <memmove>
}
    80001504:	70a2                	ld	ra,40(sp)
    80001506:	7402                	ld	s0,32(sp)
    80001508:	64e2                	ld	s1,24(sp)
    8000150a:	6942                	ld	s2,16(sp)
    8000150c:	69a2                	ld	s3,8(sp)
    8000150e:	6a02                	ld	s4,0(sp)
    80001510:	6145                	addi	sp,sp,48
    80001512:	8082                	ret
    panic("uvmfirst: more than a page");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6c50513          	addi	a0,a0,-916 # 80008180 <digits+0x140>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	028080e7          	jalr	40(ra) # 80000544 <panic>

0000000080001524 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001524:	1101                	addi	sp,sp,-32
    80001526:	ec06                	sd	ra,24(sp)
    80001528:	e822                	sd	s0,16(sp)
    8000152a:	e426                	sd	s1,8(sp)
    8000152c:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    8000152e:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    80001530:	00b67d63          	bgeu	a2,a1,8000154a <uvmdealloc+0x26>
    80001534:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001536:	6785                	lui	a5,0x1
    80001538:	17fd                	addi	a5,a5,-1
    8000153a:	00f60733          	add	a4,a2,a5
    8000153e:	767d                	lui	a2,0xfffff
    80001540:	8f71                	and	a4,a4,a2
    80001542:	97ae                	add	a5,a5,a1
    80001544:	8ff1                	and	a5,a5,a2
    80001546:	00f76863          	bltu	a4,a5,80001556 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000154a:	8526                	mv	a0,s1
    8000154c:	60e2                	ld	ra,24(sp)
    8000154e:	6442                	ld	s0,16(sp)
    80001550:	64a2                	ld	s1,8(sp)
    80001552:	6105                	addi	sp,sp,32
    80001554:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001556:	8f99                	sub	a5,a5,a4
    80001558:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000155a:	4685                	li	a3,1
    8000155c:	0007861b          	sext.w	a2,a5
    80001560:	85ba                	mv	a1,a4
    80001562:	00000097          	auipc	ra,0x0
    80001566:	e5e080e7          	jalr	-418(ra) # 800013c0 <uvmunmap>
    8000156a:	b7c5                	j	8000154a <uvmdealloc+0x26>

000000008000156c <uvmalloc>:
  if (newsz < oldsz)
    8000156c:	0ab66563          	bltu	a2,a1,80001616 <uvmalloc+0xaa>
{
    80001570:	7139                	addi	sp,sp,-64
    80001572:	fc06                	sd	ra,56(sp)
    80001574:	f822                	sd	s0,48(sp)
    80001576:	f426                	sd	s1,40(sp)
    80001578:	f04a                	sd	s2,32(sp)
    8000157a:	ec4e                	sd	s3,24(sp)
    8000157c:	e852                	sd	s4,16(sp)
    8000157e:	e456                	sd	s5,8(sp)
    80001580:	e05a                	sd	s6,0(sp)
    80001582:	0080                	addi	s0,sp,64
    80001584:	8aaa                	mv	s5,a0
    80001586:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001588:	6985                	lui	s3,0x1
    8000158a:	19fd                	addi	s3,s3,-1
    8000158c:	95ce                	add	a1,a1,s3
    8000158e:	79fd                	lui	s3,0xfffff
    80001590:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001594:	08c9f363          	bgeu	s3,a2,8000161a <uvmalloc+0xae>
    80001598:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    8000159a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000159e:	fffff097          	auipc	ra,0xfffff
    800015a2:	65e080e7          	jalr	1630(ra) # 80000bfc <kalloc>
    800015a6:	84aa                	mv	s1,a0
    if (mem == 0)
    800015a8:	c51d                	beqz	a0,800015d6 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015aa:	6605                	lui	a2,0x1
    800015ac:	4581                	li	a1,0
    800015ae:	00000097          	auipc	ra,0x0
    800015b2:	878080e7          	jalr	-1928(ra) # 80000e26 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800015b6:	875a                	mv	a4,s6
    800015b8:	86a6                	mv	a3,s1
    800015ba:	6605                	lui	a2,0x1
    800015bc:	85ca                	mv	a1,s2
    800015be:	8556                	mv	a0,s5
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	c3a080e7          	jalr	-966(ra) # 800011fa <mappages>
    800015c8:	e90d                	bnez	a0,800015fa <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    800015ca:	6785                	lui	a5,0x1
    800015cc:	993e                	add	s2,s2,a5
    800015ce:	fd4968e3          	bltu	s2,s4,8000159e <uvmalloc+0x32>
  return newsz;
    800015d2:	8552                	mv	a0,s4
    800015d4:	a809                	j	800015e6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015d6:	864e                	mv	a2,s3
    800015d8:	85ca                	mv	a1,s2
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	f48080e7          	jalr	-184(ra) # 80001524 <uvmdealloc>
      return 0;
    800015e4:	4501                	li	a0,0
}
    800015e6:	70e2                	ld	ra,56(sp)
    800015e8:	7442                	ld	s0,48(sp)
    800015ea:	74a2                	ld	s1,40(sp)
    800015ec:	7902                	ld	s2,32(sp)
    800015ee:	69e2                	ld	s3,24(sp)
    800015f0:	6a42                	ld	s4,16(sp)
    800015f2:	6aa2                	ld	s5,8(sp)
    800015f4:	6b02                	ld	s6,0(sp)
    800015f6:	6121                	addi	sp,sp,64
    800015f8:	8082                	ret
      kfree(mem);
    800015fa:	8526                	mv	a0,s1
    800015fc:	fffff097          	auipc	ra,0xfffff
    80001600:	47e080e7          	jalr	1150(ra) # 80000a7a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001604:	864e                	mv	a2,s3
    80001606:	85ca                	mv	a1,s2
    80001608:	8556                	mv	a0,s5
    8000160a:	00000097          	auipc	ra,0x0
    8000160e:	f1a080e7          	jalr	-230(ra) # 80001524 <uvmdealloc>
      return 0;
    80001612:	4501                	li	a0,0
    80001614:	bfc9                	j	800015e6 <uvmalloc+0x7a>
    return oldsz;
    80001616:	852e                	mv	a0,a1
}
    80001618:	8082                	ret
  return newsz;
    8000161a:	8532                	mv	a0,a2
    8000161c:	b7e9                	j	800015e6 <uvmalloc+0x7a>

000000008000161e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    8000161e:	7179                	addi	sp,sp,-48
    80001620:	f406                	sd	ra,40(sp)
    80001622:	f022                	sd	s0,32(sp)
    80001624:	ec26                	sd	s1,24(sp)
    80001626:	e84a                	sd	s2,16(sp)
    80001628:	e44e                	sd	s3,8(sp)
    8000162a:	e052                	sd	s4,0(sp)
    8000162c:	1800                	addi	s0,sp,48
    8000162e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    80001630:	84aa                	mv	s1,a0
    80001632:	6905                	lui	s2,0x1
    80001634:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001636:	4985                	li	s3,1
    80001638:	a821                	j	80001650 <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000163a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000163c:	0532                	slli	a0,a0,0xc
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	fe0080e7          	jalr	-32(ra) # 8000161e <freewalk>
      pagetable[i] = 0;
    80001646:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    8000164a:	04a1                	addi	s1,s1,8
    8000164c:	03248163          	beq	s1,s2,8000166e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001650:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001652:	00f57793          	andi	a5,a0,15
    80001656:	ff3782e3          	beq	a5,s3,8000163a <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    8000165a:	8905                	andi	a0,a0,1
    8000165c:	d57d                	beqz	a0,8000164a <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    8000165e:	00007517          	auipc	a0,0x7
    80001662:	b4250513          	addi	a0,a0,-1214 # 800081a0 <digits+0x160>
    80001666:	fffff097          	auipc	ra,0xfffff
    8000166a:	ede080e7          	jalr	-290(ra) # 80000544 <panic>
    }
  }
  kfree((void *)pagetable);
    8000166e:	8552                	mv	a0,s4
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	40a080e7          	jalr	1034(ra) # 80000a7a <kfree>
}
    80001678:	70a2                	ld	ra,40(sp)
    8000167a:	7402                	ld	s0,32(sp)
    8000167c:	64e2                	ld	s1,24(sp)
    8000167e:	6942                	ld	s2,16(sp)
    80001680:	69a2                	ld	s3,8(sp)
    80001682:	6a02                	ld	s4,0(sp)
    80001684:	6145                	addi	sp,sp,48
    80001686:	8082                	ret

0000000080001688 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001688:	1101                	addi	sp,sp,-32
    8000168a:	ec06                	sd	ra,24(sp)
    8000168c:	e822                	sd	s0,16(sp)
    8000168e:	e426                	sd	s1,8(sp)
    80001690:	1000                	addi	s0,sp,32
    80001692:	84aa                	mv	s1,a0
  if (sz > 0)
    80001694:	e999                	bnez	a1,800016aa <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    80001696:	8526                	mv	a0,s1
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	f86080e7          	jalr	-122(ra) # 8000161e <freewalk>
}
    800016a0:	60e2                	ld	ra,24(sp)
    800016a2:	6442                	ld	s0,16(sp)
    800016a4:	64a2                	ld	s1,8(sp)
    800016a6:	6105                	addi	sp,sp,32
    800016a8:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    800016aa:	6605                	lui	a2,0x1
    800016ac:	167d                	addi	a2,a2,-1
    800016ae:	962e                	add	a2,a2,a1
    800016b0:	4685                	li	a3,1
    800016b2:	8231                	srli	a2,a2,0xc
    800016b4:	4581                	li	a1,0
    800016b6:	00000097          	auipc	ra,0x0
    800016ba:	d0a080e7          	jalr	-758(ra) # 800013c0 <uvmunmap>
    800016be:	bfe1                	j	80001696 <uvmfree+0xe>

00000000800016c0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for (i = 0; i < sz; i += PGSIZE)
    800016c0:	ca55                	beqz	a2,80001774 <uvmcopy+0xb4>
{
    800016c2:	7139                	addi	sp,sp,-64
    800016c4:	fc06                	sd	ra,56(sp)
    800016c6:	f822                	sd	s0,48(sp)
    800016c8:	f426                	sd	s1,40(sp)
    800016ca:	f04a                	sd	s2,32(sp)
    800016cc:	ec4e                	sd	s3,24(sp)
    800016ce:	e852                	sd	s4,16(sp)
    800016d0:	e456                	sd	s5,8(sp)
    800016d2:	e05a                	sd	s6,0(sp)
    800016d4:	0080                	addi	s0,sp,64
    800016d6:	8b2a                	mv	s6,a0
    800016d8:	8aae                	mv	s5,a1
    800016da:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE)
    800016dc:	4901                	li	s2,0
  {
    if ((pte = walk(old, i, 0)) == 0)
    800016de:	4601                	li	a2,0
    800016e0:	85ca                	mv	a1,s2
    800016e2:	855a                	mv	a0,s6
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	a2e080e7          	jalr	-1490(ra) # 80001112 <walk>
    800016ec:	c121                	beqz	a0,8000172c <uvmcopy+0x6c>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
    800016ee:	6118                	ld	a4,0(a0)
    800016f0:	00177793          	andi	a5,a4,1
    800016f4:	c7a1                	beqz	a5,8000173c <uvmcopy+0x7c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016f6:	00a75993          	srli	s3,a4,0xa
    800016fa:	09b2                	slli	s3,s3,0xc
    *pte &= ~PTE_W;
    800016fc:	ffb77493          	andi	s1,a4,-5
    80001700:	e104                	sd	s1,0(a0)
    flags = PTE_FLAGS(*pte);
    incref(pa);
    80001702:	854e                	mv	a0,s3
    80001704:	fffff097          	auipc	ra,0xfffff
    80001708:	2fa080e7          	jalr	762(ra) # 800009fe <incref>
    if (mappages(new, i, PGSIZE, pa, flags) != 0)
    8000170c:	3fb4f713          	andi	a4,s1,1019
    80001710:	86ce                	mv	a3,s3
    80001712:	6605                	lui	a2,0x1
    80001714:	85ca                	mv	a1,s2
    80001716:	8556                	mv	a0,s5
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	ae2080e7          	jalr	-1310(ra) # 800011fa <mappages>
    80001720:	e515                	bnez	a0,8000174c <uvmcopy+0x8c>
  for (i = 0; i < sz; i += PGSIZE)
    80001722:	6785                	lui	a5,0x1
    80001724:	993e                	add	s2,s2,a5
    80001726:	fb496ce3          	bltu	s2,s4,800016de <uvmcopy+0x1e>
    8000172a:	a81d                	j	80001760 <uvmcopy+0xa0>
      panic("uvmcopy: pte should exist");
    8000172c:	00007517          	auipc	a0,0x7
    80001730:	a8450513          	addi	a0,a0,-1404 # 800081b0 <digits+0x170>
    80001734:	fffff097          	auipc	ra,0xfffff
    80001738:	e10080e7          	jalr	-496(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000173c:	00007517          	auipc	a0,0x7
    80001740:	a9450513          	addi	a0,a0,-1388 # 800081d0 <digits+0x190>
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	e00080e7          	jalr	-512(ra) # 80000544 <panic>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000174c:	4685                	li	a3,1
    8000174e:	00c95613          	srli	a2,s2,0xc
    80001752:	4581                	li	a1,0
    80001754:	8556                	mv	a0,s5
    80001756:	00000097          	auipc	ra,0x0
    8000175a:	c6a080e7          	jalr	-918(ra) # 800013c0 <uvmunmap>
  return -1;
    8000175e:	557d                	li	a0,-1
}
    80001760:	70e2                	ld	ra,56(sp)
    80001762:	7442                	ld	s0,48(sp)
    80001764:	74a2                	ld	s1,40(sp)
    80001766:	7902                	ld	s2,32(sp)
    80001768:	69e2                	ld	s3,24(sp)
    8000176a:	6a42                	ld	s4,16(sp)
    8000176c:	6aa2                	ld	s5,8(sp)
    8000176e:	6b02                	ld	s6,0(sp)
    80001770:	6121                	addi	sp,sp,64
    80001772:	8082                	ret
  return 0;
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret

0000000080001778 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    80001778:	1141                	addi	sp,sp,-16
    8000177a:	e406                	sd	ra,8(sp)
    8000177c:	e022                	sd	s0,0(sp)
    8000177e:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    80001780:	4601                	li	a2,0
    80001782:	00000097          	auipc	ra,0x0
    80001786:	990080e7          	jalr	-1648(ra) # 80001112 <walk>
  if (pte == 0)
    8000178a:	c901                	beqz	a0,8000179a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000178c:	611c                	ld	a5,0(a0)
    8000178e:	9bbd                	andi	a5,a5,-17
    80001790:	e11c                	sd	a5,0(a0)
}
    80001792:	60a2                	ld	ra,8(sp)
    80001794:	6402                	ld	s0,0(sp)
    80001796:	0141                	addi	sp,sp,16
    80001798:	8082                	ret
    panic("uvmclear");
    8000179a:	00007517          	auipc	a0,0x7
    8000179e:	a5650513          	addi	a0,a0,-1450 # 800081f0 <digits+0x1b0>
    800017a2:	fffff097          	auipc	ra,0xfffff
    800017a6:	da2080e7          	jalr	-606(ra) # 80000544 <panic>

00000000800017aa <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    800017aa:	cac5                	beqz	a3,8000185a <copyout+0xb0>
{
    800017ac:	7159                	addi	sp,sp,-112
    800017ae:	f486                	sd	ra,104(sp)
    800017b0:	f0a2                	sd	s0,96(sp)
    800017b2:	eca6                	sd	s1,88(sp)
    800017b4:	e8ca                	sd	s2,80(sp)
    800017b6:	e4ce                	sd	s3,72(sp)
    800017b8:	e0d2                	sd	s4,64(sp)
    800017ba:	fc56                	sd	s5,56(sp)
    800017bc:	f85a                	sd	s6,48(sp)
    800017be:	f45e                	sd	s7,40(sp)
    800017c0:	f062                	sd	s8,32(sp)
    800017c2:	ec66                	sd	s9,24(sp)
    800017c4:	e86a                	sd	s10,16(sp)
    800017c6:	e46e                	sd	s11,8(sp)
    800017c8:	1880                	addi	s0,sp,112
    800017ca:	8c2a                	mv	s8,a0
    800017cc:	8b2e                	mv	s6,a1
    800017ce:	8bb2                	mv	s7,a2
    800017d0:	8a36                	mv	s4,a3
  {
    va0 = PGROUNDDOWN(dstva);
    800017d2:	74fd                	lui	s1,0xfffff
    800017d4:	8ced                	and	s1,s1,a1
    // pa0 = walkaddr(pagetable, va0);
    if (va0 >= MAXVA)
    800017d6:	57fd                	li	a5,-1
    800017d8:	83e9                	srli	a5,a5,0x1a
    800017da:	0897e263          	bltu	a5,s1,8000185e <copyout+0xb4>
    {
      return -1;
    }
    pte_t *pte = walk(pagetable, va0, 0);
    if (0 == pte || 0 == (*pte & PTE_V) || 0 == (*pte & PTE_U))
    800017de:	4d45                	li	s10,17
    800017e0:	6d85                	lui	s11,0x1
    if (va0 >= MAXVA)
    800017e2:	8cbe                	mv	s9,a5
    800017e4:	a83d                	j	80001822 <copyout+0x78>
        return -1;
      }
    }

    pa0 = PTE2PA(*pte);
    n = PGSIZE - (dstva - va0);
    800017e6:	01b48ab3          	add	s5,s1,s11
    800017ea:	416a89b3          	sub	s3,s5,s6
    if (n > len)
    800017ee:	013a7363          	bgeu	s4,s3,800017f4 <copyout+0x4a>
    800017f2:	89d2                	mv	s3,s4
    pa0 = PTE2PA(*pte);
    800017f4:	00093783          	ld	a5,0(s2) # 1000 <_entry-0x7ffff000>
    800017f8:	83a9                	srli	a5,a5,0xa
    800017fa:	07b2                	slli	a5,a5,0xc
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017fc:	409b0533          	sub	a0,s6,s1
    80001800:	0009861b          	sext.w	a2,s3
    80001804:	85de                	mv	a1,s7
    80001806:	953e                	add	a0,a0,a5
    80001808:	fffff097          	auipc	ra,0xfffff
    8000180c:	67e080e7          	jalr	1662(ra) # 80000e86 <memmove>

    len -= n;
    80001810:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001814:	9bce                	add	s7,s7,s3
  while (len > 0)
    80001816:	040a0063          	beqz	s4,80001856 <copyout+0xac>
    if (va0 >= MAXVA)
    8000181a:	055ce463          	bltu	s9,s5,80001862 <copyout+0xb8>
    va0 = PGROUNDDOWN(dstva);
    8000181e:	84d6                	mv	s1,s5
    dstva = va0 + PGSIZE;
    80001820:	8b56                	mv	s6,s5
    pte_t *pte = walk(pagetable, va0, 0);
    80001822:	4601                	li	a2,0
    80001824:	85a6                	mv	a1,s1
    80001826:	8562                	mv	a0,s8
    80001828:	00000097          	auipc	ra,0x0
    8000182c:	8ea080e7          	jalr	-1814(ra) # 80001112 <walk>
    80001830:	892a                	mv	s2,a0
    if (0 == pte || 0 == (*pte & PTE_V) || 0 == (*pte & PTE_U))
    80001832:	c915                	beqz	a0,80001866 <copyout+0xbc>
    80001834:	611c                	ld	a5,0(a0)
    80001836:	0117f713          	andi	a4,a5,17
    8000183a:	05a71663          	bne	a4,s10,80001886 <copyout+0xdc>
    if (0 == (*pte & PTE_W))
    8000183e:	8b91                	andi	a5,a5,4
    80001840:	f3dd                	bnez	a5,800017e6 <copyout+0x3c>
      if (0 > cowfault(pagetable, va0))
    80001842:	85a6                	mv	a1,s1
    80001844:	8562                	mv	a0,s8
    80001846:	00001097          	auipc	ra,0x1
    8000184a:	5b8080e7          	jalr	1464(ra) # 80002dfe <cowfault>
    8000184e:	f8055ce3          	bgez	a0,800017e6 <copyout+0x3c>
        return -1;
    80001852:	557d                	li	a0,-1
    80001854:	a811                	j	80001868 <copyout+0xbe>
  }
  return 0;
    80001856:	4501                	li	a0,0
    80001858:	a801                	j	80001868 <copyout+0xbe>
    8000185a:	4501                	li	a0,0
}
    8000185c:	8082                	ret
      return -1;
    8000185e:	557d                	li	a0,-1
    80001860:	a021                	j	80001868 <copyout+0xbe>
    80001862:	557d                	li	a0,-1
    80001864:	a011                	j	80001868 <copyout+0xbe>
      return -1;
    80001866:	557d                	li	a0,-1
}
    80001868:	70a6                	ld	ra,104(sp)
    8000186a:	7406                	ld	s0,96(sp)
    8000186c:	64e6                	ld	s1,88(sp)
    8000186e:	6946                	ld	s2,80(sp)
    80001870:	69a6                	ld	s3,72(sp)
    80001872:	6a06                	ld	s4,64(sp)
    80001874:	7ae2                	ld	s5,56(sp)
    80001876:	7b42                	ld	s6,48(sp)
    80001878:	7ba2                	ld	s7,40(sp)
    8000187a:	7c02                	ld	s8,32(sp)
    8000187c:	6ce2                	ld	s9,24(sp)
    8000187e:	6d42                	ld	s10,16(sp)
    80001880:	6da2                	ld	s11,8(sp)
    80001882:	6165                	addi	sp,sp,112
    80001884:	8082                	ret
      return -1;
    80001886:	557d                	li	a0,-1
    80001888:	b7c5                	j	80001868 <copyout+0xbe>

000000008000188a <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    8000188a:	c6bd                	beqz	a3,800018f8 <copyin+0x6e>
{
    8000188c:	715d                	addi	sp,sp,-80
    8000188e:	e486                	sd	ra,72(sp)
    80001890:	e0a2                	sd	s0,64(sp)
    80001892:	fc26                	sd	s1,56(sp)
    80001894:	f84a                	sd	s2,48(sp)
    80001896:	f44e                	sd	s3,40(sp)
    80001898:	f052                	sd	s4,32(sp)
    8000189a:	ec56                	sd	s5,24(sp)
    8000189c:	e85a                	sd	s6,16(sp)
    8000189e:	e45e                	sd	s7,8(sp)
    800018a0:	e062                	sd	s8,0(sp)
    800018a2:	0880                	addi	s0,sp,80
    800018a4:	8b2a                	mv	s6,a0
    800018a6:	8a2e                	mv	s4,a1
    800018a8:	8c32                	mv	s8,a2
    800018aa:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800018ac:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018ae:	6a85                	lui	s5,0x1
    800018b0:	a015                	j	800018d4 <copyin+0x4a>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018b2:	9562                	add	a0,a0,s8
    800018b4:	0004861b          	sext.w	a2,s1
    800018b8:	412505b3          	sub	a1,a0,s2
    800018bc:	8552                	mv	a0,s4
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	5c8080e7          	jalr	1480(ra) # 80000e86 <memmove>

    len -= n;
    800018c6:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018ca:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018cc:	01590c33          	add	s8,s2,s5
  while (len > 0)
    800018d0:	02098263          	beqz	s3,800018f4 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800018d4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018d8:	85ca                	mv	a1,s2
    800018da:	855a                	mv	a0,s6
    800018dc:	00000097          	auipc	ra,0x0
    800018e0:	8dc080e7          	jalr	-1828(ra) # 800011b8 <walkaddr>
    if (pa0 == 0)
    800018e4:	cd01                	beqz	a0,800018fc <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018e6:	418904b3          	sub	s1,s2,s8
    800018ea:	94d6                	add	s1,s1,s5
    if (n > len)
    800018ec:	fc99f3e3          	bgeu	s3,s1,800018b2 <copyin+0x28>
    800018f0:	84ce                	mv	s1,s3
    800018f2:	b7c1                	j	800018b2 <copyin+0x28>
  }
  return 0;
    800018f4:	4501                	li	a0,0
    800018f6:	a021                	j	800018fe <copyin+0x74>
    800018f8:	4501                	li	a0,0
}
    800018fa:	8082                	ret
      return -1;
    800018fc:	557d                	li	a0,-1
}
    800018fe:	60a6                	ld	ra,72(sp)
    80001900:	6406                	ld	s0,64(sp)
    80001902:	74e2                	ld	s1,56(sp)
    80001904:	7942                	ld	s2,48(sp)
    80001906:	79a2                	ld	s3,40(sp)
    80001908:	7a02                	ld	s4,32(sp)
    8000190a:	6ae2                	ld	s5,24(sp)
    8000190c:	6b42                	ld	s6,16(sp)
    8000190e:	6ba2                	ld	s7,8(sp)
    80001910:	6c02                	ld	s8,0(sp)
    80001912:	6161                	addi	sp,sp,80
    80001914:	8082                	ret

0000000080001916 <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    80001916:	c6c5                	beqz	a3,800019be <copyinstr+0xa8>
{
    80001918:	715d                	addi	sp,sp,-80
    8000191a:	e486                	sd	ra,72(sp)
    8000191c:	e0a2                	sd	s0,64(sp)
    8000191e:	fc26                	sd	s1,56(sp)
    80001920:	f84a                	sd	s2,48(sp)
    80001922:	f44e                	sd	s3,40(sp)
    80001924:	f052                	sd	s4,32(sp)
    80001926:	ec56                	sd	s5,24(sp)
    80001928:	e85a                	sd	s6,16(sp)
    8000192a:	e45e                	sd	s7,8(sp)
    8000192c:	0880                	addi	s0,sp,80
    8000192e:	8a2a                	mv	s4,a0
    80001930:	8b2e                	mv	s6,a1
    80001932:	8bb2                	mv	s7,a2
    80001934:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001936:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001938:	6985                	lui	s3,0x1
    8000193a:	a035                	j	80001966 <copyinstr+0x50>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    8000193c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001940:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    80001942:	0017b793          	seqz	a5,a5
    80001946:	40f00533          	neg	a0,a5
  }
  else
  {
    return -1;
  }
}
    8000194a:	60a6                	ld	ra,72(sp)
    8000194c:	6406                	ld	s0,64(sp)
    8000194e:	74e2                	ld	s1,56(sp)
    80001950:	7942                	ld	s2,48(sp)
    80001952:	79a2                	ld	s3,40(sp)
    80001954:	7a02                	ld	s4,32(sp)
    80001956:	6ae2                	ld	s5,24(sp)
    80001958:	6b42                	ld	s6,16(sp)
    8000195a:	6ba2                	ld	s7,8(sp)
    8000195c:	6161                	addi	sp,sp,80
    8000195e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001960:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    80001964:	c8a9                	beqz	s1,800019b6 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001966:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000196a:	85ca                	mv	a1,s2
    8000196c:	8552                	mv	a0,s4
    8000196e:	00000097          	auipc	ra,0x0
    80001972:	84a080e7          	jalr	-1974(ra) # 800011b8 <walkaddr>
    if (pa0 == 0)
    80001976:	c131                	beqz	a0,800019ba <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001978:	41790833          	sub	a6,s2,s7
    8000197c:	984e                	add	a6,a6,s3
    if (n > max)
    8000197e:	0104f363          	bgeu	s1,a6,80001984 <copyinstr+0x6e>
    80001982:	8826                	mv	a6,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001984:	955e                	add	a0,a0,s7
    80001986:	41250533          	sub	a0,a0,s2
    while (n > 0)
    8000198a:	fc080be3          	beqz	a6,80001960 <copyinstr+0x4a>
    8000198e:	985a                	add	a6,a6,s6
    80001990:	87da                	mv	a5,s6
      if (*p == '\0')
    80001992:	41650633          	sub	a2,a0,s6
    80001996:	14fd                	addi	s1,s1,-1
    80001998:	9b26                	add	s6,s6,s1
    8000199a:	00f60733          	add	a4,a2,a5
    8000199e:	00074703          	lbu	a4,0(a4)
    800019a2:	df49                	beqz	a4,8000193c <copyinstr+0x26>
        *dst = *p;
    800019a4:	00e78023          	sb	a4,0(a5)
      --max;
    800019a8:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800019ac:	0785                	addi	a5,a5,1
    while (n > 0)
    800019ae:	ff0796e3          	bne	a5,a6,8000199a <copyinstr+0x84>
      dst++;
    800019b2:	8b42                	mv	s6,a6
    800019b4:	b775                	j	80001960 <copyinstr+0x4a>
    800019b6:	4781                	li	a5,0
    800019b8:	b769                	j	80001942 <copyinstr+0x2c>
      return -1;
    800019ba:	557d                	li	a0,-1
    800019bc:	b779                	j	8000194a <copyinstr+0x34>
  int got_null = 0;
    800019be:	4781                	li	a5,0
  if (got_null)
    800019c0:	0017b793          	seqz	a5,a5
    800019c4:	40f00533          	neg	a0,a5
}
    800019c8:	8082                	ret

00000000800019ca <sgenrand>:
static unsigned long mt[N]; /* the array for the state vector  */
static int mti = N + 1;     /* mti==N+1 means mt[N] is not initialized */

/* initializing the array with a NONZERO seed */
void sgenrand(unsigned long seed)
{
    800019ca:	1141                	addi	sp,sp,-16
    800019cc:	e422                	sd	s0,8(sp)
    800019ce:	0800                	addi	s0,sp,16
  /* setting initial seeds to mt[N] using         */
  /* the generator Line 25 of Table 1 in          */
  /* [KNUTH 1981, The Art of Computer Programming */
  /*    Vol. 2 (2nd Ed.), pp102]                  */
  mt[0] = seed & 0xffffffff;
    800019d0:	00237717          	auipc	a4,0x237
    800019d4:	b9070713          	addi	a4,a4,-1136 # 80238560 <mt>
    800019d8:	1502                	slli	a0,a0,0x20
    800019da:	9101                	srli	a0,a0,0x20
    800019dc:	e308                	sd	a0,0(a4)
  for (mti = 1; mti < N; mti++)
    800019de:	00238597          	auipc	a1,0x238
    800019e2:	efa58593          	addi	a1,a1,-262 # 802398d8 <mt+0x1378>
    mt[mti] = (69069 * mt[mti - 1]) & 0xffffffff;
    800019e6:	6645                	lui	a2,0x11
    800019e8:	dcd60613          	addi	a2,a2,-563 # 10dcd <_entry-0x7ffef233>
    800019ec:	56fd                	li	a3,-1
    800019ee:	9281                	srli	a3,a3,0x20
    800019f0:	631c                	ld	a5,0(a4)
    800019f2:	02c787b3          	mul	a5,a5,a2
    800019f6:	8ff5                	and	a5,a5,a3
    800019f8:	e71c                	sd	a5,8(a4)
  for (mti = 1; mti < N; mti++)
    800019fa:	0721                	addi	a4,a4,8
    800019fc:	feb71ae3          	bne	a4,a1,800019f0 <sgenrand+0x26>
    80001a00:	27000793          	li	a5,624
    80001a04:	00007717          	auipc	a4,0x7
    80001a08:	0ef72a23          	sw	a5,244(a4) # 80008af8 <mti>
}
    80001a0c:	6422                	ld	s0,8(sp)
    80001a0e:	0141                	addi	sp,sp,16
    80001a10:	8082                	ret

0000000080001a12 <genrand>:

long /* for integer generation */
genrand()
{
    80001a12:	1141                	addi	sp,sp,-16
    80001a14:	e406                	sd	ra,8(sp)
    80001a16:	e022                	sd	s0,0(sp)
    80001a18:	0800                	addi	s0,sp,16
  unsigned long y;
  static unsigned long mag01[2] = {0x0, MATRIX_A};
  /* mag01[x] = x * MATRIX_A  for x=0,1 */

  if (mti >= N)
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	0de7a783          	lw	a5,222(a5) # 80008af8 <mti>
    80001a22:	26f00713          	li	a4,623
    80001a26:	0ef75963          	bge	a4,a5,80001b18 <genrand+0x106>
  { /* generate N words at one time */
    int kk;

    if (mti == N + 1) /* if sgenrand() has not been called, */
    80001a2a:	27100713          	li	a4,625
    80001a2e:	12e78f63          	beq	a5,a4,80001b6c <genrand+0x15a>
      sgenrand(4357); /* a default initial seed is used   */

    for (kk = 0; kk < N - M; kk++)
    80001a32:	00237817          	auipc	a6,0x237
    80001a36:	b2e80813          	addi	a6,a6,-1234 # 80238560 <mt>
    80001a3a:	00237e17          	auipc	t3,0x237
    80001a3e:	23ee0e13          	addi	t3,t3,574 # 80238c78 <mt+0x718>
{
    80001a42:	8742                	mv	a4,a6
    {
      y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
    80001a44:	4885                	li	a7,1
    80001a46:	08fe                	slli	a7,a7,0x1f
    80001a48:	80000537          	lui	a0,0x80000
    80001a4c:	fff54513          	not	a0,a0
      mt[kk] = mt[kk + M] ^ (y >> 1) ^ mag01[y & 0x1];
    80001a50:	6585                	lui	a1,0x1
    80001a52:	c6858593          	addi	a1,a1,-920 # c68 <_entry-0x7ffff398>
    80001a56:	00007317          	auipc	t1,0x7
    80001a5a:	93230313          	addi	t1,t1,-1742 # 80008388 <mag01.1607>
      y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
    80001a5e:	631c                	ld	a5,0(a4)
    80001a60:	0117f7b3          	and	a5,a5,a7
    80001a64:	6714                	ld	a3,8(a4)
    80001a66:	8ee9                	and	a3,a3,a0
    80001a68:	8fd5                	or	a5,a5,a3
      mt[kk] = mt[kk + M] ^ (y >> 1) ^ mag01[y & 0x1];
    80001a6a:	00b70633          	add	a2,a4,a1
    80001a6e:	0017d693          	srli	a3,a5,0x1
    80001a72:	6210                	ld	a2,0(a2)
    80001a74:	8eb1                	xor	a3,a3,a2
    80001a76:	8b85                	andi	a5,a5,1
    80001a78:	078e                	slli	a5,a5,0x3
    80001a7a:	979a                	add	a5,a5,t1
    80001a7c:	639c                	ld	a5,0(a5)
    80001a7e:	8fb5                	xor	a5,a5,a3
    80001a80:	e31c                	sd	a5,0(a4)
    for (kk = 0; kk < N - M; kk++)
    80001a82:	0721                	addi	a4,a4,8
    80001a84:	fdc71de3          	bne	a4,t3,80001a5e <genrand+0x4c>
    }
    for (; kk < N - 1; kk++)
    80001a88:	6605                	lui	a2,0x1
    80001a8a:	c6060613          	addi	a2,a2,-928 # c60 <_entry-0x7ffff3a0>
    80001a8e:	9642                	add	a2,a2,a6
    {
      y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
    80001a90:	4505                	li	a0,1
    80001a92:	057e                	slli	a0,a0,0x1f
    80001a94:	800005b7          	lui	a1,0x80000
    80001a98:	fff5c593          	not	a1,a1
      mt[kk] = mt[kk + (M - N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80001a9c:	00007897          	auipc	a7,0x7
    80001aa0:	8ec88893          	addi	a7,a7,-1812 # 80008388 <mag01.1607>
      y = (mt[kk] & UPPER_MASK) | (mt[kk + 1] & LOWER_MASK);
    80001aa4:	71883783          	ld	a5,1816(a6)
    80001aa8:	8fe9                	and	a5,a5,a0
    80001aaa:	72083703          	ld	a4,1824(a6)
    80001aae:	8f6d                	and	a4,a4,a1
    80001ab0:	8fd9                	or	a5,a5,a4
      mt[kk] = mt[kk + (M - N)] ^ (y >> 1) ^ mag01[y & 0x1];
    80001ab2:	0017d713          	srli	a4,a5,0x1
    80001ab6:	00083683          	ld	a3,0(a6)
    80001aba:	8f35                	xor	a4,a4,a3
    80001abc:	8b85                	andi	a5,a5,1
    80001abe:	078e                	slli	a5,a5,0x3
    80001ac0:	97c6                	add	a5,a5,a7
    80001ac2:	639c                	ld	a5,0(a5)
    80001ac4:	8fb9                	xor	a5,a5,a4
    80001ac6:	70f83c23          	sd	a5,1816(a6)
    for (; kk < N - 1; kk++)
    80001aca:	0821                	addi	a6,a6,8
    80001acc:	fcc81ce3          	bne	a6,a2,80001aa4 <genrand+0x92>
    }
    y = (mt[N - 1] & UPPER_MASK) | (mt[0] & LOWER_MASK);
    80001ad0:	00238697          	auipc	a3,0x238
    80001ad4:	a9068693          	addi	a3,a3,-1392 # 80239560 <mt+0x1000>
    80001ad8:	3786b783          	ld	a5,888(a3)
    80001adc:	4705                	li	a4,1
    80001ade:	077e                	slli	a4,a4,0x1f
    80001ae0:	8ff9                	and	a5,a5,a4
    80001ae2:	00237717          	auipc	a4,0x237
    80001ae6:	a7e73703          	ld	a4,-1410(a4) # 80238560 <mt>
    80001aea:	1706                	slli	a4,a4,0x21
    80001aec:	9305                	srli	a4,a4,0x21
    80001aee:	8fd9                	or	a5,a5,a4
    mt[N - 1] = mt[M - 1] ^ (y >> 1) ^ mag01[y & 0x1];
    80001af0:	0017d713          	srli	a4,a5,0x1
    80001af4:	c606b603          	ld	a2,-928(a3)
    80001af8:	8f31                	xor	a4,a4,a2
    80001afa:	8b85                	andi	a5,a5,1
    80001afc:	078e                	slli	a5,a5,0x3
    80001afe:	00007617          	auipc	a2,0x7
    80001b02:	88a60613          	addi	a2,a2,-1910 # 80008388 <mag01.1607>
    80001b06:	97b2                	add	a5,a5,a2
    80001b08:	639c                	ld	a5,0(a5)
    80001b0a:	8fb9                	xor	a5,a5,a4
    80001b0c:	36f6bc23          	sd	a5,888(a3)

    mti = 0;
    80001b10:	00007797          	auipc	a5,0x7
    80001b14:	fe07a423          	sw	zero,-24(a5) # 80008af8 <mti>
  }

  y = mt[mti++];
    80001b18:	00007717          	auipc	a4,0x7
    80001b1c:	fe070713          	addi	a4,a4,-32 # 80008af8 <mti>
    80001b20:	431c                	lw	a5,0(a4)
    80001b22:	0017869b          	addiw	a3,a5,1
    80001b26:	c314                	sw	a3,0(a4)
    80001b28:	078e                	slli	a5,a5,0x3
    80001b2a:	00237717          	auipc	a4,0x237
    80001b2e:	a3670713          	addi	a4,a4,-1482 # 80238560 <mt>
    80001b32:	97ba                	add	a5,a5,a4
    80001b34:	6398                	ld	a4,0(a5)
  y ^= TEMPERING_SHIFT_U(y);
    80001b36:	00b75793          	srli	a5,a4,0xb
    80001b3a:	8f3d                	xor	a4,a4,a5
  y ^= TEMPERING_SHIFT_S(y) & TEMPERING_MASK_B;
    80001b3c:	013a67b7          	lui	a5,0x13a6
    80001b40:	8ad78793          	addi	a5,a5,-1875 # 13a58ad <_entry-0x7ec5a753>
    80001b44:	8ff9                	and	a5,a5,a4
    80001b46:	079e                	slli	a5,a5,0x7
    80001b48:	8fb9                	xor	a5,a5,a4
  y ^= TEMPERING_SHIFT_T(y) & TEMPERING_MASK_C;
    80001b4a:	00f79713          	slli	a4,a5,0xf
    80001b4e:	077e36b7          	lui	a3,0x77e3
    80001b52:	0696                	slli	a3,a3,0x5
    80001b54:	8f75                	and	a4,a4,a3
    80001b56:	8fb9                	xor	a5,a5,a4
  y ^= TEMPERING_SHIFT_L(y);
    80001b58:	0127d513          	srli	a0,a5,0x12
    80001b5c:	8fa9                	xor	a5,a5,a0

  // Strip off uppermost bit because we want a long,
  // not an unsigned long
  return y & RAND_MAX;
    80001b5e:	02179513          	slli	a0,a5,0x21
}
    80001b62:	9105                	srli	a0,a0,0x21
    80001b64:	60a2                	ld	ra,8(sp)
    80001b66:	6402                	ld	s0,0(sp)
    80001b68:	0141                	addi	sp,sp,16
    80001b6a:	8082                	ret
      sgenrand(4357); /* a default initial seed is used   */
    80001b6c:	6505                	lui	a0,0x1
    80001b6e:	10550513          	addi	a0,a0,261 # 1105 <_entry-0x7fffeefb>
    80001b72:	00000097          	auipc	ra,0x0
    80001b76:	e58080e7          	jalr	-424(ra) # 800019ca <sgenrand>
    80001b7a:	bd65                	j	80001a32 <genrand+0x20>

0000000080001b7c <random_at_most>:

// Assumes 0 <= max <= RAND_MAX
// Returns in the half-open interval [0, max]
long random_at_most(long max)
{
    80001b7c:	1101                	addi	sp,sp,-32
    80001b7e:	ec06                	sd	ra,24(sp)
    80001b80:	e822                	sd	s0,16(sp)
    80001b82:	e426                	sd	s1,8(sp)
    80001b84:	e04a                	sd	s2,0(sp)
    80001b86:	1000                	addi	s0,sp,32
  unsigned long
      // max <= RAND_MAX < ULONG_MAX, so this is okay.
      num_bins = (unsigned long)max + 1,
    80001b88:	0505                	addi	a0,a0,1
      num_rand = (unsigned long)RAND_MAX + 1,
      bin_size = num_rand / num_bins,
    80001b8a:	4485                	li	s1,1
    80001b8c:	04fe                	slli	s1,s1,0x1f
    80001b8e:	02a4d933          	divu	s2,s1,a0
      defect = num_rand % num_bins;
    80001b92:	02a4f533          	remu	a0,s1,a0
  do
  {
    x = genrand();
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned long)x);
    80001b96:	4485                	li	s1,1
    80001b98:	04fe                	slli	s1,s1,0x1f
    80001b9a:	8c89                	sub	s1,s1,a0
    x = genrand();
    80001b9c:	00000097          	auipc	ra,0x0
    80001ba0:	e76080e7          	jalr	-394(ra) # 80001a12 <genrand>
  while (num_rand - defect <= (unsigned long)x);
    80001ba4:	fe957ce3          	bgeu	a0,s1,80001b9c <random_at_most+0x20>

  // Truncated division is intentional
  return x / bin_size;
}
    80001ba8:	03255533          	divu	a0,a0,s2
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6902                	ld	s2,0(sp)
    80001bb4:	6105                	addi	sp,sp,32
    80001bb6:	8082                	ret

0000000080001bb8 <max>:

int max(int a, int b)
{
    80001bb8:	1141                	addi	sp,sp,-16
    80001bba:	e422                	sd	s0,8(sp)
    80001bbc:	0800                	addi	s0,sp,16
  return a > b ? a : b;
    80001bbe:	87ae                	mv	a5,a1
    80001bc0:	00a5d363          	bge	a1,a0,80001bc6 <max+0xe>
    80001bc4:	87aa                	mv	a5,a0
}
    80001bc6:	0007851b          	sext.w	a0,a5
    80001bca:	6422                	ld	s0,8(sp)
    80001bcc:	0141                	addi	sp,sp,16
    80001bce:	8082                	ret

0000000080001bd0 <min>:

int min(int a, int b)
{
    80001bd0:	1141                	addi	sp,sp,-16
    80001bd2:	e422                	sd	s0,8(sp)
    80001bd4:	0800                	addi	s0,sp,16
  return a < b ? a : b;
    80001bd6:	87ae                	mv	a5,a1
    80001bd8:	00b55363          	bge	a0,a1,80001bde <min+0xe>
    80001bdc:	87aa                	mv	a5,a0
}
    80001bde:	0007851b          	sext.w	a0,a5
    80001be2:	6422                	ld	s0,8(sp)
    80001be4:	0141                	addi	sp,sp,16
    80001be6:	8082                	ret

0000000080001be8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001be8:	7139                	addi	sp,sp,-64
    80001bea:	fc06                	sd	ra,56(sp)
    80001bec:	f822                	sd	s0,48(sp)
    80001bee:	f426                	sd	s1,40(sp)
    80001bf0:	f04a                	sd	s2,32(sp)
    80001bf2:	ec4e                	sd	s3,24(sp)
    80001bf4:	e852                	sd	s4,16(sp)
    80001bf6:	e456                	sd	s5,8(sp)
    80001bf8:	e05a                	sd	s6,0(sp)
    80001bfa:	0080                	addi	s0,sp,64
    80001bfc:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001bfe:	0022f497          	auipc	s1,0x22f
    80001c02:	76248493          	addi	s1,s1,1890 # 80231360 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001c06:	8b26                	mv	s6,s1
    80001c08:	00006a97          	auipc	s5,0x6
    80001c0c:	3f8a8a93          	addi	s5,s5,1016 # 80008000 <etext>
    80001c10:	04000937          	lui	s2,0x4000
    80001c14:	197d                	addi	s2,s2,-1
    80001c16:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001c18:	00237a17          	auipc	s4,0x237
    80001c1c:	948a0a13          	addi	s4,s4,-1720 # 80238560 <mt>
    char *pa = kalloc();
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	fdc080e7          	jalr	-36(ra) # 80000bfc <kalloc>
    80001c28:	862a                	mv	a2,a0
    if (pa == 0)
    80001c2a:	c131                	beqz	a0,80001c6e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001c2c:	416485b3          	sub	a1,s1,s6
    80001c30:	858d                	srai	a1,a1,0x3
    80001c32:	000ab783          	ld	a5,0(s5)
    80001c36:	02f585b3          	mul	a1,a1,a5
    80001c3a:	2585                	addiw	a1,a1,1
    80001c3c:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c40:	4719                	li	a4,6
    80001c42:	6685                	lui	a3,0x1
    80001c44:	40b905b3          	sub	a1,s2,a1
    80001c48:	854e                	mv	a0,s3
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	650080e7          	jalr	1616(ra) # 8000129a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c52:	1c848493          	addi	s1,s1,456
    80001c56:	fd4495e3          	bne	s1,s4,80001c20 <proc_mapstacks+0x38>
  }
}
    80001c5a:	70e2                	ld	ra,56(sp)
    80001c5c:	7442                	ld	s0,48(sp)
    80001c5e:	74a2                	ld	s1,40(sp)
    80001c60:	7902                	ld	s2,32(sp)
    80001c62:	69e2                	ld	s3,24(sp)
    80001c64:	6a42                	ld	s4,16(sp)
    80001c66:	6aa2                	ld	s5,8(sp)
    80001c68:	6b02                	ld	s6,0(sp)
    80001c6a:	6121                	addi	sp,sp,64
    80001c6c:	8082                	ret
      panic("kalloc");
    80001c6e:	00006517          	auipc	a0,0x6
    80001c72:	59250513          	addi	a0,a0,1426 # 80008200 <digits+0x1c0>
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	8ce080e7          	jalr	-1842(ra) # 80000544 <panic>

0000000080001c7e <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001c7e:	7139                	addi	sp,sp,-64
    80001c80:	fc06                	sd	ra,56(sp)
    80001c82:	f822                	sd	s0,48(sp)
    80001c84:	f426                	sd	s1,40(sp)
    80001c86:	f04a                	sd	s2,32(sp)
    80001c88:	ec4e                	sd	s3,24(sp)
    80001c8a:	e852                	sd	s4,16(sp)
    80001c8c:	e456                	sd	s5,8(sp)
    80001c8e:	e05a                	sd	s6,0(sp)
    80001c90:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001c92:	00006597          	auipc	a1,0x6
    80001c96:	57658593          	addi	a1,a1,1398 # 80008208 <digits+0x1c8>
    80001c9a:	0022f517          	auipc	a0,0x22f
    80001c9e:	29650513          	addi	a0,a0,662 # 80230f30 <pid_lock>
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	ff8080e7          	jalr	-8(ra) # 80000c9a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001caa:	00006597          	auipc	a1,0x6
    80001cae:	56658593          	addi	a1,a1,1382 # 80008210 <digits+0x1d0>
    80001cb2:	0022f517          	auipc	a0,0x22f
    80001cb6:	29650513          	addi	a0,a0,662 # 80230f48 <wait_lock>
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	fe0080e7          	jalr	-32(ra) # 80000c9a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cc2:	0022f497          	auipc	s1,0x22f
    80001cc6:	69e48493          	addi	s1,s1,1694 # 80231360 <proc>
  {
    initlock(&p->lock, "proc");
    80001cca:	00006b17          	auipc	s6,0x6
    80001cce:	556b0b13          	addi	s6,s6,1366 # 80008220 <digits+0x1e0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001cd2:	8aa6                	mv	s5,s1
    80001cd4:	00006a17          	auipc	s4,0x6
    80001cd8:	32ca0a13          	addi	s4,s4,812 # 80008000 <etext>
    80001cdc:	04000937          	lui	s2,0x4000
    80001ce0:	197d                	addi	s2,s2,-1
    80001ce2:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001ce4:	00237997          	auipc	s3,0x237
    80001ce8:	87c98993          	addi	s3,s3,-1924 # 80238560 <mt>
    initlock(&p->lock, "proc");
    80001cec:	85da                	mv	a1,s6
    80001cee:	8526                	mv	a0,s1
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	faa080e7          	jalr	-86(ra) # 80000c9a <initlock>
    p->state = UNUSED;
    80001cf8:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001cfc:	415487b3          	sub	a5,s1,s5
    80001d00:	878d                	srai	a5,a5,0x3
    80001d02:	000a3703          	ld	a4,0(s4)
    80001d06:	02e787b3          	mul	a5,a5,a4
    80001d0a:	2785                	addiw	a5,a5,1
    80001d0c:	00d7979b          	slliw	a5,a5,0xd
    80001d10:	40f907b3          	sub	a5,s2,a5
    80001d14:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001d16:	1c848493          	addi	s1,s1,456
    80001d1a:	fd3499e3          	bne	s1,s3,80001cec <procinit+0x6e>
  }
}
    80001d1e:	70e2                	ld	ra,56(sp)
    80001d20:	7442                	ld	s0,48(sp)
    80001d22:	74a2                	ld	s1,40(sp)
    80001d24:	7902                	ld	s2,32(sp)
    80001d26:	69e2                	ld	s3,24(sp)
    80001d28:	6a42                	ld	s4,16(sp)
    80001d2a:	6aa2                	ld	s5,8(sp)
    80001d2c:	6b02                	ld	s6,0(sp)
    80001d2e:	6121                	addi	sp,sp,64
    80001d30:	8082                	ret

0000000080001d32 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001d32:	1141                	addi	sp,sp,-16
    80001d34:	e422                	sd	s0,8(sp)
    80001d36:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d38:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d3a:	2501                	sext.w	a0,a0
    80001d3c:	6422                	ld	s0,8(sp)
    80001d3e:	0141                	addi	sp,sp,16
    80001d40:	8082                	ret

0000000080001d42 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001d42:	1141                	addi	sp,sp,-16
    80001d44:	e422                	sd	s0,8(sp)
    80001d46:	0800                	addi	s0,sp,16
    80001d48:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d4a:	2781                	sext.w	a5,a5
    80001d4c:	079e                	slli	a5,a5,0x7
  return c;
}
    80001d4e:	0022f517          	auipc	a0,0x22f
    80001d52:	21250513          	addi	a0,a0,530 # 80230f60 <cpus>
    80001d56:	953e                	add	a0,a0,a5
    80001d58:	6422                	ld	s0,8(sp)
    80001d5a:	0141                	addi	sp,sp,16
    80001d5c:	8082                	ret

0000000080001d5e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001d5e:	1101                	addi	sp,sp,-32
    80001d60:	ec06                	sd	ra,24(sp)
    80001d62:	e822                	sd	s0,16(sp)
    80001d64:	e426                	sd	s1,8(sp)
    80001d66:	1000                	addi	s0,sp,32
  push_off();
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	f76080e7          	jalr	-138(ra) # 80000cde <push_off>
    80001d70:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d72:	2781                	sext.w	a5,a5
    80001d74:	079e                	slli	a5,a5,0x7
    80001d76:	0022f717          	auipc	a4,0x22f
    80001d7a:	1ba70713          	addi	a4,a4,442 # 80230f30 <pid_lock>
    80001d7e:	97ba                	add	a5,a5,a4
    80001d80:	7b84                	ld	s1,48(a5)
  pop_off();
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	ffc080e7          	jalr	-4(ra) # 80000d7e <pop_off>
  return p;
}
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	60e2                	ld	ra,24(sp)
    80001d8e:	6442                	ld	s0,16(sp)
    80001d90:	64a2                	ld	s1,8(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret

0000000080001d96 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d96:	1141                	addi	sp,sp,-16
    80001d98:	e406                	sd	ra,8(sp)
    80001d9a:	e022                	sd	s0,0(sp)
    80001d9c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	fc0080e7          	jalr	-64(ra) # 80001d5e <myproc>
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	038080e7          	jalr	56(ra) # 80000dde <release>

  if (first)
    80001dae:	00007797          	auipc	a5,0x7
    80001db2:	d427a783          	lw	a5,-702(a5) # 80008af0 <first.1818>
    80001db6:	eb89                	bnez	a5,80001dc8 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001db8:	00001097          	auipc	ra,0x1
    80001dbc:	0da080e7          	jalr	218(ra) # 80002e92 <usertrapret>
}
    80001dc0:	60a2                	ld	ra,8(sp)
    80001dc2:	6402                	ld	s0,0(sp)
    80001dc4:	0141                	addi	sp,sp,16
    80001dc6:	8082                	ret
    first = 0;
    80001dc8:	00007797          	auipc	a5,0x7
    80001dcc:	d207a423          	sw	zero,-728(a5) # 80008af0 <first.1818>
    fsinit(ROOTDEV);
    80001dd0:	4505                	li	a0,1
    80001dd2:	00002097          	auipc	ra,0x2
    80001dd6:	12a080e7          	jalr	298(ra) # 80003efc <fsinit>
    80001dda:	bff9                	j	80001db8 <forkret+0x22>

0000000080001ddc <get_dynamic_priority>:
{
    80001ddc:	1141                	addi	sp,sp,-16
    80001dde:	e422                	sd	s0,8(sp)
    80001de0:	0800                	addi	s0,sp,16
  p->niceness = 5;
    80001de2:	4795                	li	a5,5
    80001de4:	18f52e23          	sw	a5,412(a0)
  if (p->last_ticks_scheduled && p->sched_ct != 0)
    80001de8:	595c                	lw	a5,52(a0)
    80001dea:	c39d                	beqz	a5,80001e10 <get_dynamic_priority+0x34>
    80001dec:	1c052783          	lw	a5,448(a0)
    80001df0:	c385                	beqz	a5,80001e10 <get_dynamic_priority+0x34>
    int time_diff = p->sched_ct + p->last_sleep;
    80001df2:	16c52703          	lw	a4,364(a0)
    80001df6:	9fb9                	addw	a5,a5,a4
    80001df8:	0007869b          	sext.w	a3,a5
    if (time_diff != 0)
    80001dfc:	ca91                	beqz	a3,80001e10 <get_dynamic_priority+0x34>
      p->niceness = ((sleeping) / (time_diff)) * 10;
    80001dfe:	02f747bb          	divw	a5,a4,a5
    80001e02:	0027971b          	slliw	a4,a5,0x2
    80001e06:	9fb9                	addw	a5,a5,a4
    80001e08:	0017979b          	slliw	a5,a5,0x1
    80001e0c:	18f52e23          	sw	a5,412(a0)
  uint64 DP = max(0, min(p->stat_priority - p->niceness + 5, 100));
    80001e10:	19852783          	lw	a5,408(a0)
    80001e14:	19c52503          	lw	a0,412(a0)
    80001e18:	40a7853b          	subw	a0,a5,a0
    80001e1c:	2515                	addiw	a0,a0,5
  return a < b ? a : b;
    80001e1e:	0005071b          	sext.w	a4,a0
    80001e22:	06400793          	li	a5,100
    80001e26:	00e7d463          	bge	a5,a4,80001e2e <get_dynamic_priority+0x52>
    80001e2a:	06400513          	li	a0,100
  return a > b ? a : b;
    80001e2e:	0005079b          	sext.w	a5,a0
    80001e32:	fff7c793          	not	a5,a5
    80001e36:	97fd                	srai	a5,a5,0x3f
    80001e38:	8d7d                	and	a0,a0,a5
}
    80001e3a:	2501                	sext.w	a0,a0
    80001e3c:	6422                	ld	s0,8(sp)
    80001e3e:	0141                	addi	sp,sp,16
    80001e40:	8082                	ret

0000000080001e42 <allocpid>:
{
    80001e42:	1101                	addi	sp,sp,-32
    80001e44:	ec06                	sd	ra,24(sp)
    80001e46:	e822                	sd	s0,16(sp)
    80001e48:	e426                	sd	s1,8(sp)
    80001e4a:	e04a                	sd	s2,0(sp)
    80001e4c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001e4e:	0022f917          	auipc	s2,0x22f
    80001e52:	0e290913          	addi	s2,s2,226 # 80230f30 <pid_lock>
    80001e56:	854a                	mv	a0,s2
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	ed2080e7          	jalr	-302(ra) # 80000d2a <acquire>
  pid = nextpid;
    80001e60:	00007797          	auipc	a5,0x7
    80001e64:	c9478793          	addi	a5,a5,-876 # 80008af4 <nextpid>
    80001e68:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001e6a:	0014871b          	addiw	a4,s1,1
    80001e6e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001e70:	854a                	mv	a0,s2
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	f6c080e7          	jalr	-148(ra) # 80000dde <release>
}
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	60e2                	ld	ra,24(sp)
    80001e7e:	6442                	ld	s0,16(sp)
    80001e80:	64a2                	ld	s1,8(sp)
    80001e82:	6902                	ld	s2,0(sp)
    80001e84:	6105                	addi	sp,sp,32
    80001e86:	8082                	ret

0000000080001e88 <set_priority>:
{
    80001e88:	7179                	addi	sp,sp,-48
    80001e8a:	f406                	sd	ra,40(sp)
    80001e8c:	f022                	sd	s0,32(sp)
    80001e8e:	ec26                	sd	s1,24(sp)
    80001e90:	e84a                	sd	s2,16(sp)
    80001e92:	e44e                	sd	s3,8(sp)
    80001e94:	e052                	sd	s4,0(sp)
    80001e96:	1800                	addi	s0,sp,48
    80001e98:	892e                	mv	s2,a1
  if (new_static_priority < 0 || new_static_priority > 100)
    80001e9a:	8a2a                	mv	s4,a0
    80001e9c:	06400793          	li	a5,100
  for (p = proc; p < &proc[NPROC]; p++)
    80001ea0:	0022f497          	auipc	s1,0x22f
    80001ea4:	4c048493          	addi	s1,s1,1216 # 80231360 <proc>
    80001ea8:	00236997          	auipc	s3,0x236
    80001eac:	6b898993          	addi	s3,s3,1720 # 80238560 <mt>
  if (new_static_priority < 0 || new_static_priority > 100)
    80001eb0:	02a7ee63          	bltu	a5,a0,80001eec <set_priority+0x64>
    acquire(&p->lock);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	e74080e7          	jalr	-396(ra) # 80000d2a <acquire>
    if (p->pid == proc_pid)
    80001ebe:	589c                	lw	a5,48(s1)
    80001ec0:	05278063          	beq	a5,s2,80001f00 <set_priority+0x78>
    release(&p->lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	f18080e7          	jalr	-232(ra) # 80000dde <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ece:	1c848493          	addi	s1,s1,456
    80001ed2:	ff3491e3          	bne	s1,s3,80001eb4 <set_priority+0x2c>
    printf("no process with pid : %d exists\n", proc_pid);
    80001ed6:	85ca                	mv	a1,s2
    80001ed8:	00006517          	auipc	a0,0x6
    80001edc:	3c050513          	addi	a0,a0,960 # 80008298 <digits+0x258>
    80001ee0:	ffffe097          	auipc	ra,0xffffe
    80001ee4:	6ae080e7          	jalr	1710(ra) # 8000058e <printf>
  int old_static_priority = -1;
    80001ee8:	59fd                	li	s3,-1
    80001eea:	a089                	j	80001f2c <set_priority+0xa4>
    printf("<new_static_priority> should be in range [0 - 100]\n");
    80001eec:	00006517          	auipc	a0,0x6
    80001ef0:	33c50513          	addi	a0,a0,828 # 80008228 <digits+0x1e8>
    80001ef4:	ffffe097          	auipc	ra,0xffffe
    80001ef8:	69a080e7          	jalr	1690(ra) # 8000058e <printf>
    return -1;
    80001efc:	59fd                	li	s3,-1
    80001efe:	a03d                	j	80001f2c <set_priority+0xa4>
      old_static_priority = p->stat_priority;
    80001f00:	1984a983          	lw	s3,408(s1)
      p->stat_priority = new_static_priority;
    80001f04:	1944ac23          	sw	s4,408(s1)
    printf("priority of proc wit pid : %d changed from %d to %d \n", p->pid, old_static_priority, new_static_priority);
    80001f08:	86d2                	mv	a3,s4
    80001f0a:	864e                	mv	a2,s3
    80001f0c:	85ca                	mv	a1,s2
    80001f0e:	00006517          	auipc	a0,0x6
    80001f12:	35250513          	addi	a0,a0,850 # 80008260 <digits+0x220>
    80001f16:	ffffe097          	auipc	ra,0xffffe
    80001f1a:	678080e7          	jalr	1656(ra) # 8000058e <printf>
    release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	ebe080e7          	jalr	-322(ra) # 80000dde <release>
    if (old_static_priority < new_static_priority)
    80001f28:	0149cb63          	blt	s3,s4,80001f3e <set_priority+0xb6>
}
    80001f2c:	854e                	mv	a0,s3
    80001f2e:	70a2                	ld	ra,40(sp)
    80001f30:	7402                	ld	s0,32(sp)
    80001f32:	64e2                	ld	s1,24(sp)
    80001f34:	6942                	ld	s2,16(sp)
    80001f36:	69a2                	ld	s3,8(sp)
    80001f38:	6a02                	ld	s4,0(sp)
    80001f3a:	6145                	addi	sp,sp,48
    80001f3c:	8082                	ret
      p->last_run = 0;
    80001f3e:	1604a423          	sw	zero,360(s1)
      p->last_sleep = 0;
    80001f42:	1604a623          	sw	zero,364(s1)
    80001f46:	b7dd                	j	80001f2c <set_priority+0xa4>

0000000080001f48 <proc_pagetable>:
{
    80001f48:	1101                	addi	sp,sp,-32
    80001f4a:	ec06                	sd	ra,24(sp)
    80001f4c:	e822                	sd	s0,16(sp)
    80001f4e:	e426                	sd	s1,8(sp)
    80001f50:	e04a                	sd	s2,0(sp)
    80001f52:	1000                	addi	s0,sp,32
    80001f54:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	52e080e7          	jalr	1326(ra) # 80001484 <uvmcreate>
    80001f5e:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001f60:	c121                	beqz	a0,80001fa0 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f62:	4729                	li	a4,10
    80001f64:	00005697          	auipc	a3,0x5
    80001f68:	09c68693          	addi	a3,a3,156 # 80007000 <_trampoline>
    80001f6c:	6605                	lui	a2,0x1
    80001f6e:	040005b7          	lui	a1,0x4000
    80001f72:	15fd                	addi	a1,a1,-1
    80001f74:	05b2                	slli	a1,a1,0xc
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	284080e7          	jalr	644(ra) # 800011fa <mappages>
    80001f7e:	02054863          	bltz	a0,80001fae <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f82:	4719                	li	a4,6
    80001f84:	05893683          	ld	a3,88(s2)
    80001f88:	6605                	lui	a2,0x1
    80001f8a:	020005b7          	lui	a1,0x2000
    80001f8e:	15fd                	addi	a1,a1,-1
    80001f90:	05b6                	slli	a1,a1,0xd
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	266080e7          	jalr	614(ra) # 800011fa <mappages>
    80001f9c:	02054163          	bltz	a0,80001fbe <proc_pagetable+0x76>
}
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	60e2                	ld	ra,24(sp)
    80001fa4:	6442                	ld	s0,16(sp)
    80001fa6:	64a2                	ld	s1,8(sp)
    80001fa8:	6902                	ld	s2,0(sp)
    80001faa:	6105                	addi	sp,sp,32
    80001fac:	8082                	ret
    uvmfree(pagetable, 0);
    80001fae:	4581                	li	a1,0
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	6d6080e7          	jalr	1750(ra) # 80001688 <uvmfree>
    return 0;
    80001fba:	4481                	li	s1,0
    80001fbc:	b7d5                	j	80001fa0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fbe:	4681                	li	a3,0
    80001fc0:	4605                	li	a2,1
    80001fc2:	040005b7          	lui	a1,0x4000
    80001fc6:	15fd                	addi	a1,a1,-1
    80001fc8:	05b2                	slli	a1,a1,0xc
    80001fca:	8526                	mv	a0,s1
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	3f4080e7          	jalr	1012(ra) # 800013c0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001fd4:	4581                	li	a1,0
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	6b0080e7          	jalr	1712(ra) # 80001688 <uvmfree>
    return 0;
    80001fe0:	4481                	li	s1,0
    80001fe2:	bf7d                	j	80001fa0 <proc_pagetable+0x58>

0000000080001fe4 <proc_freepagetable>:
{
    80001fe4:	1101                	addi	sp,sp,-32
    80001fe6:	ec06                	sd	ra,24(sp)
    80001fe8:	e822                	sd	s0,16(sp)
    80001fea:	e426                	sd	s1,8(sp)
    80001fec:	e04a                	sd	s2,0(sp)
    80001fee:	1000                	addi	s0,sp,32
    80001ff0:	84aa                	mv	s1,a0
    80001ff2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ff4:	4681                	li	a3,0
    80001ff6:	4605                	li	a2,1
    80001ff8:	040005b7          	lui	a1,0x4000
    80001ffc:	15fd                	addi	a1,a1,-1
    80001ffe:	05b2                	slli	a1,a1,0xc
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	3c0080e7          	jalr	960(ra) # 800013c0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002008:	4681                	li	a3,0
    8000200a:	4605                	li	a2,1
    8000200c:	020005b7          	lui	a1,0x2000
    80002010:	15fd                	addi	a1,a1,-1
    80002012:	05b6                	slli	a1,a1,0xd
    80002014:	8526                	mv	a0,s1
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	3aa080e7          	jalr	938(ra) # 800013c0 <uvmunmap>
  uvmfree(pagetable, sz);
    8000201e:	85ca                	mv	a1,s2
    80002020:	8526                	mv	a0,s1
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	666080e7          	jalr	1638(ra) # 80001688 <uvmfree>
}
    8000202a:	60e2                	ld	ra,24(sp)
    8000202c:	6442                	ld	s0,16(sp)
    8000202e:	64a2                	ld	s1,8(sp)
    80002030:	6902                	ld	s2,0(sp)
    80002032:	6105                	addi	sp,sp,32
    80002034:	8082                	ret

0000000080002036 <freeproc>:
{
    80002036:	1101                	addi	sp,sp,-32
    80002038:	ec06                	sd	ra,24(sp)
    8000203a:	e822                	sd	s0,16(sp)
    8000203c:	e426                	sd	s1,8(sp)
    8000203e:	1000                	addi	s0,sp,32
    80002040:	84aa                	mv	s1,a0
  if (p->trapframe)
    80002042:	6d28                	ld	a0,88(a0)
    80002044:	c509                	beqz	a0,8000204e <freeproc+0x18>
    kfree((void *)p->trapframe);
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	a34080e7          	jalr	-1484(ra) # 80000a7a <kfree>
  if (p->cpy_trapframe)
    8000204e:	1904b503          	ld	a0,400(s1)
    80002052:	c509                	beqz	a0,8000205c <freeproc+0x26>
    kfree((void *)p->cpy_trapframe);
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	a26080e7          	jalr	-1498(ra) # 80000a7a <kfree>
  p->trapframe = 0;
    8000205c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80002060:	68a8                	ld	a0,80(s1)
    80002062:	c511                	beqz	a0,8000206e <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    80002064:	64ac                	ld	a1,72(s1)
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	f7e080e7          	jalr	-130(ra) # 80001fe4 <proc_freepagetable>
  p->pagetable = 0;
    8000206e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002072:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80002076:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000207a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    8000207e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002082:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002086:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000208a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    8000208e:	0004ac23          	sw	zero,24(s1)
}
    80002092:	60e2                	ld	ra,24(sp)
    80002094:	6442                	ld	s0,16(sp)
    80002096:	64a2                	ld	s1,8(sp)
    80002098:	6105                	addi	sp,sp,32
    8000209a:	8082                	ret

000000008000209c <allocproc>:
{
    8000209c:	1101                	addi	sp,sp,-32
    8000209e:	ec06                	sd	ra,24(sp)
    800020a0:	e822                	sd	s0,16(sp)
    800020a2:	e426                	sd	s1,8(sp)
    800020a4:	e04a                	sd	s2,0(sp)
    800020a6:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    800020a8:	0022f497          	auipc	s1,0x22f
    800020ac:	2b848493          	addi	s1,s1,696 # 80231360 <proc>
    800020b0:	00236917          	auipc	s2,0x236
    800020b4:	4b090913          	addi	s2,s2,1200 # 80238560 <mt>
    acquire(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	c70080e7          	jalr	-912(ra) # 80000d2a <acquire>
    if (p->state == UNUSED)
    800020c2:	4c9c                	lw	a5,24(s1)
    800020c4:	cf81                	beqz	a5,800020dc <allocproc+0x40>
      release(&p->lock);
    800020c6:	8526                	mv	a0,s1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	d16080e7          	jalr	-746(ra) # 80000dde <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800020d0:	1c848493          	addi	s1,s1,456
    800020d4:	ff2492e3          	bne	s1,s2,800020b8 <allocproc+0x1c>
  return 0;
    800020d8:	4481                	li	s1,0
    800020da:	a07d                	j	80002188 <allocproc+0xec>
  p->pid = allocpid();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	d66080e7          	jalr	-666(ra) # 80001e42 <allocpid>
    800020e4:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020e6:	4785                	li	a5,1
    800020e8:	cc9c                	sw	a5,24(s1)
  p->init_time = ticks;
    800020ea:	00007797          	auipc	a5,0x7
    800020ee:	bd67e783          	lwu	a5,-1066(a5) # 80008cc0 <ticks>
    800020f2:	1af4b023          	sd	a5,416(s1)
  p->run_time = 0;
    800020f6:	1a04b423          	sd	zero,424(s1)
  p->end_time = 0;
    800020fa:	1a04b823          	sd	zero,432(s1)
  p->sleep_time = 0;
    800020fe:	1a04bc23          	sd	zero,440(s1)
  p->sched_ct = 0;
    80002102:	1c04a023          	sw	zero,448(s1)
  p->tickets = 1;
    80002106:	4785                	li	a5,1
    80002108:	18f4b423          	sd	a5,392(s1)
  p->last_run = 0;
    8000210c:	1604a423          	sw	zero,360(s1)
  p->last_sleep = 0;
    80002110:	1604a623          	sw	zero,364(s1)
  p->last_ticks_scheduled = 0;
    80002114:	0204aa23          	sw	zero,52(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	ae4080e7          	jalr	-1308(ra) # 80000bfc <kalloc>
    80002120:	892a                	mv	s2,a0
    80002122:	eca8                	sd	a0,88(s1)
    80002124:	c92d                	beqz	a0,80002196 <allocproc+0xfa>
  if ((p->cpy_trapframe = (struct trapframe *)kalloc()) == 0)
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	ad6080e7          	jalr	-1322(ra) # 80000bfc <kalloc>
    8000212e:	892a                	mv	s2,a0
    80002130:	18a4b823          	sd	a0,400(s1)
    80002134:	cd2d                	beqz	a0,800021ae <allocproc+0x112>
  p->stat_priority = 60;
    80002136:	03c00793          	li	a5,60
    8000213a:	18f4ac23          	sw	a5,408(s1)
  p->niceness = 5;
    8000213e:	4795                	li	a5,5
    80002140:	18f4ae23          	sw	a5,412(s1)
  p->is_sigalarm = 0;
    80002144:	1604aa23          	sw	zero,372(s1)
  p->clockval = 0;
    80002148:	1604ac23          	sw	zero,376(s1)
  p->completed_clockval = 0;
    8000214c:	1604ae23          	sw	zero,380(s1)
  p->handler = 0;
    80002150:	1804b023          	sd	zero,384(s1)
  p->pagetable = proc_pagetable(p);
    80002154:	8526                	mv	a0,s1
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	df2080e7          	jalr	-526(ra) # 80001f48 <proc_pagetable>
    8000215e:	892a                	mv	s2,a0
    80002160:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80002162:	cd29                	beqz	a0,800021bc <allocproc+0x120>
  memset(&p->context, 0, sizeof(p->context));
    80002164:	07000613          	li	a2,112
    80002168:	4581                	li	a1,0
    8000216a:	06048513          	addi	a0,s1,96
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	cb8080e7          	jalr	-840(ra) # 80000e26 <memset>
  p->context.ra = (uint64)forkret;
    80002176:	00000797          	auipc	a5,0x0
    8000217a:	c2078793          	addi	a5,a5,-992 # 80001d96 <forkret>
    8000217e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002180:	60bc                	ld	a5,64(s1)
    80002182:	6705                	lui	a4,0x1
    80002184:	97ba                	add	a5,a5,a4
    80002186:	f4bc                	sd	a5,104(s1)
}
    80002188:	8526                	mv	a0,s1
    8000218a:	60e2                	ld	ra,24(sp)
    8000218c:	6442                	ld	s0,16(sp)
    8000218e:	64a2                	ld	s1,8(sp)
    80002190:	6902                	ld	s2,0(sp)
    80002192:	6105                	addi	sp,sp,32
    80002194:	8082                	ret
    freeproc(p);
    80002196:	8526                	mv	a0,s1
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	e9e080e7          	jalr	-354(ra) # 80002036 <freeproc>
    release(&p->lock);
    800021a0:	8526                	mv	a0,s1
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	c3c080e7          	jalr	-964(ra) # 80000dde <release>
    return 0;
    800021aa:	84ca                	mv	s1,s2
    800021ac:	bff1                	j	80002188 <allocproc+0xec>
    release(&p->lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	c2e080e7          	jalr	-978(ra) # 80000dde <release>
    return 0;
    800021b8:	84ca                	mv	s1,s2
    800021ba:	b7f9                	j	80002188 <allocproc+0xec>
    freeproc(p);
    800021bc:	8526                	mv	a0,s1
    800021be:	00000097          	auipc	ra,0x0
    800021c2:	e78080e7          	jalr	-392(ra) # 80002036 <freeproc>
    release(&p->lock);
    800021c6:	8526                	mv	a0,s1
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	c16080e7          	jalr	-1002(ra) # 80000dde <release>
    return 0;
    800021d0:	84ca                	mv	s1,s2
    800021d2:	bf5d                	j	80002188 <allocproc+0xec>

00000000800021d4 <userinit>:
{
    800021d4:	1101                	addi	sp,sp,-32
    800021d6:	ec06                	sd	ra,24(sp)
    800021d8:	e822                	sd	s0,16(sp)
    800021da:	e426                	sd	s1,8(sp)
    800021dc:	1000                	addi	s0,sp,32
  p = allocproc();
    800021de:	00000097          	auipc	ra,0x0
    800021e2:	ebe080e7          	jalr	-322(ra) # 8000209c <allocproc>
    800021e6:	84aa                	mv	s1,a0
  initproc = p;
    800021e8:	00007797          	auipc	a5,0x7
    800021ec:	aca7b823          	sd	a0,-1328(a5) # 80008cb8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    800021f0:	03400613          	li	a2,52
    800021f4:	00007597          	auipc	a1,0x7
    800021f8:	90c58593          	addi	a1,a1,-1780 # 80008b00 <initcode>
    800021fc:	6928                	ld	a0,80(a0)
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	2b4080e7          	jalr	692(ra) # 800014b2 <uvmfirst>
  p->sz = PGSIZE;
    80002206:	6785                	lui	a5,0x1
    80002208:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    8000220a:	6cb8                	ld	a4,88(s1)
    8000220c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80002210:	6cb8                	ld	a4,88(s1)
    80002212:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002214:	4641                	li	a2,16
    80002216:	00006597          	auipc	a1,0x6
    8000221a:	0aa58593          	addi	a1,a1,170 # 800082c0 <digits+0x280>
    8000221e:	15848513          	addi	a0,s1,344
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	d56080e7          	jalr	-682(ra) # 80000f78 <safestrcpy>
  p->cwd = namei("/");
    8000222a:	00006517          	auipc	a0,0x6
    8000222e:	0a650513          	addi	a0,a0,166 # 800082d0 <digits+0x290>
    80002232:	00002097          	auipc	ra,0x2
    80002236:	6ec080e7          	jalr	1772(ra) # 8000491e <namei>
    8000223a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000223e:	478d                	li	a5,3
    80002240:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	b9a080e7          	jalr	-1126(ra) # 80000dde <release>
}
    8000224c:	60e2                	ld	ra,24(sp)
    8000224e:	6442                	ld	s0,16(sp)
    80002250:	64a2                	ld	s1,8(sp)
    80002252:	6105                	addi	sp,sp,32
    80002254:	8082                	ret

0000000080002256 <growproc>:
{
    80002256:	1101                	addi	sp,sp,-32
    80002258:	ec06                	sd	ra,24(sp)
    8000225a:	e822                	sd	s0,16(sp)
    8000225c:	e426                	sd	s1,8(sp)
    8000225e:	e04a                	sd	s2,0(sp)
    80002260:	1000                	addi	s0,sp,32
    80002262:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002264:	00000097          	auipc	ra,0x0
    80002268:	afa080e7          	jalr	-1286(ra) # 80001d5e <myproc>
    8000226c:	84aa                	mv	s1,a0
  sz = p->sz;
    8000226e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80002270:	01204c63          	bgtz	s2,80002288 <growproc+0x32>
  else if (n < 0)
    80002274:	02094663          	bltz	s2,800022a0 <growproc+0x4a>
  p->sz = sz;
    80002278:	e4ac                	sd	a1,72(s1)
  return 0;
    8000227a:	4501                	li	a0,0
}
    8000227c:	60e2                	ld	ra,24(sp)
    8000227e:	6442                	ld	s0,16(sp)
    80002280:	64a2                	ld	s1,8(sp)
    80002282:	6902                	ld	s2,0(sp)
    80002284:	6105                	addi	sp,sp,32
    80002286:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002288:	4691                	li	a3,4
    8000228a:	00b90633          	add	a2,s2,a1
    8000228e:	6928                	ld	a0,80(a0)
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	2dc080e7          	jalr	732(ra) # 8000156c <uvmalloc>
    80002298:	85aa                	mv	a1,a0
    8000229a:	fd79                	bnez	a0,80002278 <growproc+0x22>
      return -1;
    8000229c:	557d                	li	a0,-1
    8000229e:	bff9                	j	8000227c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022a0:	00b90633          	add	a2,s2,a1
    800022a4:	6928                	ld	a0,80(a0)
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	27e080e7          	jalr	638(ra) # 80001524 <uvmdealloc>
    800022ae:	85aa                	mv	a1,a0
    800022b0:	b7e1                	j	80002278 <growproc+0x22>

00000000800022b2 <fork>:
{
    800022b2:	7179                	addi	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	e052                	sd	s4,0(sp)
    800022c0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	a9c080e7          	jalr	-1380(ra) # 80001d5e <myproc>
    800022ca:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	dd0080e7          	jalr	-560(ra) # 8000209c <allocproc>
    800022d4:	10050f63          	beqz	a0,800023f2 <fork+0x140>
    800022d8:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800022da:	04893603          	ld	a2,72(s2)
    800022de:	692c                	ld	a1,80(a0)
    800022e0:	05093503          	ld	a0,80(s2)
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	3dc080e7          	jalr	988(ra) # 800016c0 <uvmcopy>
    800022ec:	04054a63          	bltz	a0,80002340 <fork+0x8e>
  np->sz = p->sz;
    800022f0:	04893783          	ld	a5,72(s2)
    800022f4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800022f8:	05893683          	ld	a3,88(s2)
    800022fc:	87b6                	mv	a5,a3
    800022fe:	0589b703          	ld	a4,88(s3)
    80002302:	12068693          	addi	a3,a3,288
    80002306:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000230a:	6788                	ld	a0,8(a5)
    8000230c:	6b8c                	ld	a1,16(a5)
    8000230e:	6f90                	ld	a2,24(a5)
    80002310:	01073023          	sd	a6,0(a4)
    80002314:	e708                	sd	a0,8(a4)
    80002316:	eb0c                	sd	a1,16(a4)
    80002318:	ef10                	sd	a2,24(a4)
    8000231a:	02078793          	addi	a5,a5,32
    8000231e:	02070713          	addi	a4,a4,32
    80002322:	fed792e3          	bne	a5,a3,80002306 <fork+0x54>
  np->trapframe->a0 = 0;
    80002326:	0589b783          	ld	a5,88(s3)
    8000232a:	0607b823          	sd	zero,112(a5)
  np->bitmask = p->bitmask;
    8000232e:	17092783          	lw	a5,368(s2)
    80002332:	16f9a823          	sw	a5,368(s3)
    80002336:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    8000233a:	15000a13          	li	s4,336
    8000233e:	a03d                	j	8000236c <fork+0xba>
    freeproc(np);
    80002340:	854e                	mv	a0,s3
    80002342:	00000097          	auipc	ra,0x0
    80002346:	cf4080e7          	jalr	-780(ra) # 80002036 <freeproc>
    release(&np->lock);
    8000234a:	854e                	mv	a0,s3
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	a92080e7          	jalr	-1390(ra) # 80000dde <release>
    return -1;
    80002354:	5a7d                	li	s4,-1
    80002356:	a069                	j	800023e0 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002358:	00003097          	auipc	ra,0x3
    8000235c:	c5c080e7          	jalr	-932(ra) # 80004fb4 <filedup>
    80002360:	009987b3          	add	a5,s3,s1
    80002364:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80002366:	04a1                	addi	s1,s1,8
    80002368:	01448763          	beq	s1,s4,80002376 <fork+0xc4>
    if (p->ofile[i])
    8000236c:	009907b3          	add	a5,s2,s1
    80002370:	6388                	ld	a0,0(a5)
    80002372:	f17d                	bnez	a0,80002358 <fork+0xa6>
    80002374:	bfcd                	j	80002366 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002376:	15093503          	ld	a0,336(s2)
    8000237a:	00002097          	auipc	ra,0x2
    8000237e:	dc0080e7          	jalr	-576(ra) # 8000413a <idup>
    80002382:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002386:	4641                	li	a2,16
    80002388:	15890593          	addi	a1,s2,344
    8000238c:	15898513          	addi	a0,s3,344
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	be8080e7          	jalr	-1048(ra) # 80000f78 <safestrcpy>
  pid = np->pid;
    80002398:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    8000239c:	854e                	mv	a0,s3
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	a40080e7          	jalr	-1472(ra) # 80000dde <release>
  acquire(&wait_lock);
    800023a6:	0022f497          	auipc	s1,0x22f
    800023aa:	ba248493          	addi	s1,s1,-1118 # 80230f48 <wait_lock>
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	97a080e7          	jalr	-1670(ra) # 80000d2a <acquire>
  np->parent = p;
    800023b8:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	a20080e7          	jalr	-1504(ra) # 80000dde <release>
  acquire(&np->lock);
    800023c6:	854e                	mv	a0,s3
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	962080e7          	jalr	-1694(ra) # 80000d2a <acquire>
  np->state = RUNNABLE;
    800023d0:	478d                	li	a5,3
    800023d2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800023d6:	854e                	mv	a0,s3
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	a06080e7          	jalr	-1530(ra) # 80000dde <release>
}
    800023e0:	8552                	mv	a0,s4
    800023e2:	70a2                	ld	ra,40(sp)
    800023e4:	7402                	ld	s0,32(sp)
    800023e6:	64e2                	ld	s1,24(sp)
    800023e8:	6942                	ld	s2,16(sp)
    800023ea:	69a2                	ld	s3,8(sp)
    800023ec:	6a02                	ld	s4,0(sp)
    800023ee:	6145                	addi	sp,sp,48
    800023f0:	8082                	ret
    return -1;
    800023f2:	5a7d                	li	s4,-1
    800023f4:	b7f5                	j	800023e0 <fork+0x12e>

00000000800023f6 <lock_ptable>:
{
    800023f6:	1101                	addi	sp,sp,-32
    800023f8:	ec06                	sd	ra,24(sp)
    800023fa:	e822                	sd	s0,16(sp)
    800023fc:	e426                	sd	s1,8(sp)
    800023fe:	e04a                	sd	s2,0(sp)
    80002400:	1000                	addi	s0,sp,32
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002402:	0022f497          	auipc	s1,0x22f
    80002406:	f5e48493          	addi	s1,s1,-162 # 80231360 <proc>
    8000240a:	00236917          	auipc	s2,0x236
    8000240e:	15690913          	addi	s2,s2,342 # 80238560 <mt>
    acquire(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	916080e7          	jalr	-1770(ra) # 80000d2a <acquire>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    8000241c:	1c848493          	addi	s1,s1,456
    80002420:	ff2499e3          	bne	s1,s2,80002412 <lock_ptable+0x1c>
}
    80002424:	60e2                	ld	ra,24(sp)
    80002426:	6442                	ld	s0,16(sp)
    80002428:	64a2                	ld	s1,8(sp)
    8000242a:	6902                	ld	s2,0(sp)
    8000242c:	6105                	addi	sp,sp,32
    8000242e:	8082                	ret

0000000080002430 <release_ptable>:
{
    80002430:	7179                	addi	sp,sp,-48
    80002432:	f406                	sd	ra,40(sp)
    80002434:	f022                	sd	s0,32(sp)
    80002436:	ec26                	sd	s1,24(sp)
    80002438:	e84a                	sd	s2,16(sp)
    8000243a:	e44e                	sd	s3,8(sp)
    8000243c:	1800                	addi	s0,sp,48
    8000243e:	892a                	mv	s2,a0
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002440:	0022f497          	auipc	s1,0x22f
    80002444:	f2048493          	addi	s1,s1,-224 # 80231360 <proc>
    80002448:	00236997          	auipc	s3,0x236
    8000244c:	11898993          	addi	s3,s3,280 # 80238560 <mt>
    80002450:	a811                	j	80002464 <release_ptable+0x34>
      release(&p->lock);
    80002452:	8526                	mv	a0,s1
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	98a080e7          	jalr	-1654(ra) # 80000dde <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    8000245c:	1c848493          	addi	s1,s1,456
    80002460:	01348563          	beq	s1,s3,8000246a <release_ptable+0x3a>
    if (p != e)
    80002464:	fe9917e3          	bne	s2,s1,80002452 <release_ptable+0x22>
    80002468:	bfd5                	j	8000245c <release_ptable+0x2c>
}
    8000246a:	70a2                	ld	ra,40(sp)
    8000246c:	7402                	ld	s0,32(sp)
    8000246e:	64e2                	ld	s1,24(sp)
    80002470:	6942                	ld	s2,16(sp)
    80002472:	69a2                	ld	s3,8(sp)
    80002474:	6145                	addi	sp,sp,48
    80002476:	8082                	ret

0000000080002478 <scheduler>:
{
    80002478:	7139                	addi	sp,sp,-64
    8000247a:	fc06                	sd	ra,56(sp)
    8000247c:	f822                	sd	s0,48(sp)
    8000247e:	f426                	sd	s1,40(sp)
    80002480:	f04a                	sd	s2,32(sp)
    80002482:	ec4e                	sd	s3,24(sp)
    80002484:	e852                	sd	s4,16(sp)
    80002486:	e456                	sd	s5,8(sp)
    80002488:	e05a                	sd	s6,0(sp)
    8000248a:	0080                	addi	s0,sp,64
    8000248c:	8792                	mv	a5,tp
  int id = r_tp();
    8000248e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002490:	00779a93          	slli	s5,a5,0x7
    80002494:	0022f717          	auipc	a4,0x22f
    80002498:	a9c70713          	addi	a4,a4,-1380 # 80230f30 <pid_lock>
    8000249c:	9756                	add	a4,a4,s5
    8000249e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800024a2:	0022f717          	auipc	a4,0x22f
    800024a6:	ac670713          	addi	a4,a4,-1338 # 80230f68 <cpus+0x8>
    800024aa:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    800024ac:	498d                	li	s3,3
        p->state = RUNNING;
    800024ae:	4b11                	li	s6,4
        c->proc = p;
    800024b0:	079e                	slli	a5,a5,0x7
    800024b2:	0022fa17          	auipc	s4,0x22f
    800024b6:	a7ea0a13          	addi	s4,s4,-1410 # 80230f30 <pid_lock>
    800024ba:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800024bc:	00236917          	auipc	s2,0x236
    800024c0:	0a490913          	addi	s2,s2,164 # 80238560 <mt>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024c4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800024c8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024cc:	10079073          	csrw	sstatus,a5
    800024d0:	0022f497          	auipc	s1,0x22f
    800024d4:	e9048493          	addi	s1,s1,-368 # 80231360 <proc>
    800024d8:	a03d                	j	80002506 <scheduler+0x8e>
        p->state = RUNNING;
    800024da:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800024de:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800024e2:	06048593          	addi	a1,s1,96
    800024e6:	8556                	mv	a0,s5
    800024e8:	00001097          	auipc	ra,0x1
    800024ec:	86c080e7          	jalr	-1940(ra) # 80002d54 <swtch>
        c->proc = 0;
    800024f0:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	8e8080e7          	jalr	-1816(ra) # 80000dde <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800024fe:	1c848493          	addi	s1,s1,456
    80002502:	fd2481e3          	beq	s1,s2,800024c4 <scheduler+0x4c>
      acquire(&p->lock);
    80002506:	8526                	mv	a0,s1
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	822080e7          	jalr	-2014(ra) # 80000d2a <acquire>
      if (p->state == RUNNABLE)
    80002510:	4c9c                	lw	a5,24(s1)
    80002512:	ff3791e3          	bne	a5,s3,800024f4 <scheduler+0x7c>
    80002516:	b7d1                	j	800024da <scheduler+0x62>

0000000080002518 <update_time>:
{
    80002518:	7179                	addi	sp,sp,-48
    8000251a:	f406                	sd	ra,40(sp)
    8000251c:	f022                	sd	s0,32(sp)
    8000251e:	ec26                	sd	s1,24(sp)
    80002520:	e84a                	sd	s2,16(sp)
    80002522:	e44e                	sd	s3,8(sp)
    80002524:	e052                	sd	s4,0(sp)
    80002526:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002528:	0022f497          	auipc	s1,0x22f
    8000252c:	e3848493          	addi	s1,s1,-456 # 80231360 <proc>
    switch (p->state)
    80002530:	4a09                	li	s4,2
    80002532:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002534:	00236917          	auipc	s2,0x236
    80002538:	02c90913          	addi	s2,s2,44 # 80238560 <mt>
    8000253c:	a839                	j	8000255a <update_time+0x42>
      p->sleep_time++;
    8000253e:	1b84b783          	ld	a5,440(s1)
    80002542:	0785                	addi	a5,a5,1
    80002544:	1af4bc23          	sd	a5,440(s1)
    release(&p->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	fffff097          	auipc	ra,0xfffff
    8000254e:	894080e7          	jalr	-1900(ra) # 80000dde <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002552:	1c848493          	addi	s1,s1,456
    80002556:	03248263          	beq	s1,s2,8000257a <update_time+0x62>
    acquire(&p->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	7ce080e7          	jalr	1998(ra) # 80000d2a <acquire>
    switch (p->state)
    80002564:	4c9c                	lw	a5,24(s1)
    80002566:	fd478ce3          	beq	a5,s4,8000253e <update_time+0x26>
    8000256a:	fd379fe3          	bne	a5,s3,80002548 <update_time+0x30>
      p->run_time++;
    8000256e:	1a84b783          	ld	a5,424(s1)
    80002572:	0785                	addi	a5,a5,1
    80002574:	1af4b423          	sd	a5,424(s1)
      break;
    80002578:	bfc1                	j	80002548 <update_time+0x30>
}
    8000257a:	70a2                	ld	ra,40(sp)
    8000257c:	7402                	ld	s0,32(sp)
    8000257e:	64e2                	ld	s1,24(sp)
    80002580:	6942                	ld	s2,16(sp)
    80002582:	69a2                	ld	s3,8(sp)
    80002584:	6a02                	ld	s4,0(sp)
    80002586:	6145                	addi	sp,sp,48
    80002588:	8082                	ret

000000008000258a <sched>:
{
    8000258a:	7179                	addi	sp,sp,-48
    8000258c:	f406                	sd	ra,40(sp)
    8000258e:	f022                	sd	s0,32(sp)
    80002590:	ec26                	sd	s1,24(sp)
    80002592:	e84a                	sd	s2,16(sp)
    80002594:	e44e                	sd	s3,8(sp)
    80002596:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	7c6080e7          	jalr	1990(ra) # 80001d5e <myproc>
    800025a0:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	70e080e7          	jalr	1806(ra) # 80000cb0 <holding>
    800025aa:	c93d                	beqz	a0,80002620 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025ac:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800025ae:	2781                	sext.w	a5,a5
    800025b0:	079e                	slli	a5,a5,0x7
    800025b2:	0022f717          	auipc	a4,0x22f
    800025b6:	97e70713          	addi	a4,a4,-1666 # 80230f30 <pid_lock>
    800025ba:	97ba                	add	a5,a5,a4
    800025bc:	0a87a703          	lw	a4,168(a5)
    800025c0:	4785                	li	a5,1
    800025c2:	06f71763          	bne	a4,a5,80002630 <sched+0xa6>
  if (p->state == RUNNING)
    800025c6:	4c98                	lw	a4,24(s1)
    800025c8:	4791                	li	a5,4
    800025ca:	06f70b63          	beq	a4,a5,80002640 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025d2:	8b89                	andi	a5,a5,2
  if (intr_get())
    800025d4:	efb5                	bnez	a5,80002650 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025d6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025d8:	0022f917          	auipc	s2,0x22f
    800025dc:	95890913          	addi	s2,s2,-1704 # 80230f30 <pid_lock>
    800025e0:	2781                	sext.w	a5,a5
    800025e2:	079e                	slli	a5,a5,0x7
    800025e4:	97ca                	add	a5,a5,s2
    800025e6:	0ac7a983          	lw	s3,172(a5)
    800025ea:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800025ec:	2781                	sext.w	a5,a5
    800025ee:	079e                	slli	a5,a5,0x7
    800025f0:	0022f597          	auipc	a1,0x22f
    800025f4:	97858593          	addi	a1,a1,-1672 # 80230f68 <cpus+0x8>
    800025f8:	95be                	add	a1,a1,a5
    800025fa:	06048513          	addi	a0,s1,96
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	756080e7          	jalr	1878(ra) # 80002d54 <swtch>
    80002606:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002608:	2781                	sext.w	a5,a5
    8000260a:	079e                	slli	a5,a5,0x7
    8000260c:	97ca                	add	a5,a5,s2
    8000260e:	0b37a623          	sw	s3,172(a5)
}
    80002612:	70a2                	ld	ra,40(sp)
    80002614:	7402                	ld	s0,32(sp)
    80002616:	64e2                	ld	s1,24(sp)
    80002618:	6942                	ld	s2,16(sp)
    8000261a:	69a2                	ld	s3,8(sp)
    8000261c:	6145                	addi	sp,sp,48
    8000261e:	8082                	ret
    panic("sched p->lock");
    80002620:	00006517          	auipc	a0,0x6
    80002624:	cb850513          	addi	a0,a0,-840 # 800082d8 <digits+0x298>
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	f1c080e7          	jalr	-228(ra) # 80000544 <panic>
    panic("sched locks");
    80002630:	00006517          	auipc	a0,0x6
    80002634:	cb850513          	addi	a0,a0,-840 # 800082e8 <digits+0x2a8>
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	f0c080e7          	jalr	-244(ra) # 80000544 <panic>
    panic("sched running");
    80002640:	00006517          	auipc	a0,0x6
    80002644:	cb850513          	addi	a0,a0,-840 # 800082f8 <digits+0x2b8>
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	efc080e7          	jalr	-260(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002650:	00006517          	auipc	a0,0x6
    80002654:	cb850513          	addi	a0,a0,-840 # 80008308 <digits+0x2c8>
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	eec080e7          	jalr	-276(ra) # 80000544 <panic>

0000000080002660 <yield>:
{
    80002660:	1101                	addi	sp,sp,-32
    80002662:	ec06                	sd	ra,24(sp)
    80002664:	e822                	sd	s0,16(sp)
    80002666:	e426                	sd	s1,8(sp)
    80002668:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	6f4080e7          	jalr	1780(ra) # 80001d5e <myproc>
    80002672:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	6b6080e7          	jalr	1718(ra) # 80000d2a <acquire>
  p->state = RUNNABLE;
    8000267c:	478d                	li	a5,3
    8000267e:	cc9c                	sw	a5,24(s1)
  sched();
    80002680:	00000097          	auipc	ra,0x0
    80002684:	f0a080e7          	jalr	-246(ra) # 8000258a <sched>
  release(&p->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	754080e7          	jalr	1876(ra) # 80000dde <release>
}
    80002692:	60e2                	ld	ra,24(sp)
    80002694:	6442                	ld	s0,16(sp)
    80002696:	64a2                	ld	s1,8(sp)
    80002698:	6105                	addi	sp,sp,32
    8000269a:	8082                	ret

000000008000269c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000269c:	7179                	addi	sp,sp,-48
    8000269e:	f406                	sd	ra,40(sp)
    800026a0:	f022                	sd	s0,32(sp)
    800026a2:	ec26                	sd	s1,24(sp)
    800026a4:	e84a                	sd	s2,16(sp)
    800026a6:	e44e                	sd	s3,8(sp)
    800026a8:	1800                	addi	s0,sp,48
    800026aa:	89aa                	mv	s3,a0
    800026ac:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	6b0080e7          	jalr	1712(ra) # 80001d5e <myproc>
    800026b6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	672080e7          	jalr	1650(ra) # 80000d2a <acquire>
  release(lk);
    800026c0:	854a                	mv	a0,s2
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	71c080e7          	jalr	1820(ra) # 80000dde <release>

  // Go to sleep.
  p->chan = chan;
    800026ca:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800026ce:	4789                	li	a5,2
    800026d0:	cc9c                	sw	a5,24(s1)

  sched();
    800026d2:	00000097          	auipc	ra,0x0
    800026d6:	eb8080e7          	jalr	-328(ra) # 8000258a <sched>

  // Tidy up.
  p->chan = 0;
    800026da:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800026de:	8526                	mv	a0,s1
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	6fe080e7          	jalr	1790(ra) # 80000dde <release>
  acquire(lk);
    800026e8:	854a                	mv	a0,s2
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	640080e7          	jalr	1600(ra) # 80000d2a <acquire>
}
    800026f2:	70a2                	ld	ra,40(sp)
    800026f4:	7402                	ld	s0,32(sp)
    800026f6:	64e2                	ld	s1,24(sp)
    800026f8:	6942                	ld	s2,16(sp)
    800026fa:	69a2                	ld	s3,8(sp)
    800026fc:	6145                	addi	sp,sp,48
    800026fe:	8082                	ret

0000000080002700 <wait>:
{
    80002700:	715d                	addi	sp,sp,-80
    80002702:	e486                	sd	ra,72(sp)
    80002704:	e0a2                	sd	s0,64(sp)
    80002706:	fc26                	sd	s1,56(sp)
    80002708:	f84a                	sd	s2,48(sp)
    8000270a:	f44e                	sd	s3,40(sp)
    8000270c:	f052                	sd	s4,32(sp)
    8000270e:	ec56                	sd	s5,24(sp)
    80002710:	e85a                	sd	s6,16(sp)
    80002712:	e45e                	sd	s7,8(sp)
    80002714:	e062                	sd	s8,0(sp)
    80002716:	0880                	addi	s0,sp,80
    80002718:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000271a:	fffff097          	auipc	ra,0xfffff
    8000271e:	644080e7          	jalr	1604(ra) # 80001d5e <myproc>
    80002722:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002724:	0022f517          	auipc	a0,0x22f
    80002728:	82450513          	addi	a0,a0,-2012 # 80230f48 <wait_lock>
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	5fe080e7          	jalr	1534(ra) # 80000d2a <acquire>
    havekids = 0;
    80002734:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002736:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002738:	00236997          	auipc	s3,0x236
    8000273c:	e2898993          	addi	s3,s3,-472 # 80238560 <mt>
        havekids = 1;
    80002740:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002742:	0022fc17          	auipc	s8,0x22f
    80002746:	806c0c13          	addi	s8,s8,-2042 # 80230f48 <wait_lock>
    havekids = 0;
    8000274a:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000274c:	0022f497          	auipc	s1,0x22f
    80002750:	c1448493          	addi	s1,s1,-1004 # 80231360 <proc>
    80002754:	a0bd                	j	800027c2 <wait+0xc2>
          pid = pp->pid;
    80002756:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000275a:	000b0e63          	beqz	s6,80002776 <wait+0x76>
    8000275e:	4691                	li	a3,4
    80002760:	02c48613          	addi	a2,s1,44
    80002764:	85da                	mv	a1,s6
    80002766:	05093503          	ld	a0,80(s2)
    8000276a:	fffff097          	auipc	ra,0xfffff
    8000276e:	040080e7          	jalr	64(ra) # 800017aa <copyout>
    80002772:	02054563          	bltz	a0,8000279c <wait+0x9c>
          freeproc(pp);
    80002776:	8526                	mv	a0,s1
    80002778:	00000097          	auipc	ra,0x0
    8000277c:	8be080e7          	jalr	-1858(ra) # 80002036 <freeproc>
          release(&pp->lock);
    80002780:	8526                	mv	a0,s1
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	65c080e7          	jalr	1628(ra) # 80000dde <release>
          release(&wait_lock);
    8000278a:	0022e517          	auipc	a0,0x22e
    8000278e:	7be50513          	addi	a0,a0,1982 # 80230f48 <wait_lock>
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	64c080e7          	jalr	1612(ra) # 80000dde <release>
          return pid;
    8000279a:	a09d                	j	80002800 <wait+0x100>
            release(&pp->lock);
    8000279c:	8526                	mv	a0,s1
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	640080e7          	jalr	1600(ra) # 80000dde <release>
            release(&wait_lock);
    800027a6:	0022e517          	auipc	a0,0x22e
    800027aa:	7a250513          	addi	a0,a0,1954 # 80230f48 <wait_lock>
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	630080e7          	jalr	1584(ra) # 80000dde <release>
            return -1;
    800027b6:	59fd                	li	s3,-1
    800027b8:	a0a1                	j	80002800 <wait+0x100>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800027ba:	1c848493          	addi	s1,s1,456
    800027be:	03348463          	beq	s1,s3,800027e6 <wait+0xe6>
      if (pp->parent == p)
    800027c2:	7c9c                	ld	a5,56(s1)
    800027c4:	ff279be3          	bne	a5,s2,800027ba <wait+0xba>
        acquire(&pp->lock);
    800027c8:	8526                	mv	a0,s1
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	560080e7          	jalr	1376(ra) # 80000d2a <acquire>
        if (pp->state == ZOMBIE)
    800027d2:	4c9c                	lw	a5,24(s1)
    800027d4:	f94781e3          	beq	a5,s4,80002756 <wait+0x56>
        release(&pp->lock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	604080e7          	jalr	1540(ra) # 80000dde <release>
        havekids = 1;
    800027e2:	8756                	mv	a4,s5
    800027e4:	bfd9                	j	800027ba <wait+0xba>
    if (!havekids || p->killed)
    800027e6:	c701                	beqz	a4,800027ee <wait+0xee>
    800027e8:	02892783          	lw	a5,40(s2)
    800027ec:	c79d                	beqz	a5,8000281a <wait+0x11a>
      release(&wait_lock);
    800027ee:	0022e517          	auipc	a0,0x22e
    800027f2:	75a50513          	addi	a0,a0,1882 # 80230f48 <wait_lock>
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	5e8080e7          	jalr	1512(ra) # 80000dde <release>
      return -1;
    800027fe:	59fd                	li	s3,-1
}
    80002800:	854e                	mv	a0,s3
    80002802:	60a6                	ld	ra,72(sp)
    80002804:	6406                	ld	s0,64(sp)
    80002806:	74e2                	ld	s1,56(sp)
    80002808:	7942                	ld	s2,48(sp)
    8000280a:	79a2                	ld	s3,40(sp)
    8000280c:	7a02                	ld	s4,32(sp)
    8000280e:	6ae2                	ld	s5,24(sp)
    80002810:	6b42                	ld	s6,16(sp)
    80002812:	6ba2                	ld	s7,8(sp)
    80002814:	6c02                	ld	s8,0(sp)
    80002816:	6161                	addi	sp,sp,80
    80002818:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000281a:	85e2                	mv	a1,s8
    8000281c:	854a                	mv	a0,s2
    8000281e:	00000097          	auipc	ra,0x0
    80002822:	e7e080e7          	jalr	-386(ra) # 8000269c <sleep>
    havekids = 0;
    80002826:	b715                	j	8000274a <wait+0x4a>

0000000080002828 <waitx>:
{
    80002828:	711d                	addi	sp,sp,-96
    8000282a:	ec86                	sd	ra,88(sp)
    8000282c:	e8a2                	sd	s0,80(sp)
    8000282e:	e4a6                	sd	s1,72(sp)
    80002830:	e0ca                	sd	s2,64(sp)
    80002832:	fc4e                	sd	s3,56(sp)
    80002834:	f852                	sd	s4,48(sp)
    80002836:	f456                	sd	s5,40(sp)
    80002838:	f05a                	sd	s6,32(sp)
    8000283a:	ec5e                	sd	s7,24(sp)
    8000283c:	e862                	sd	s8,16(sp)
    8000283e:	e466                	sd	s9,8(sp)
    80002840:	e06a                	sd	s10,0(sp)
    80002842:	1080                	addi	s0,sp,96
    80002844:	8b2a                	mv	s6,a0
    80002846:	8c2e                	mv	s8,a1
    80002848:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    8000284a:	fffff097          	auipc	ra,0xfffff
    8000284e:	514080e7          	jalr	1300(ra) # 80001d5e <myproc>
    80002852:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002854:	0022e517          	auipc	a0,0x22e
    80002858:	6f450513          	addi	a0,a0,1780 # 80230f48 <wait_lock>
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	4ce080e7          	jalr	1230(ra) # 80000d2a <acquire>
    havekids = 0;
    80002864:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    80002866:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002868:	00236997          	auipc	s3,0x236
    8000286c:	cf898993          	addi	s3,s3,-776 # 80238560 <mt>
        havekids = 1;
    80002870:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002872:	0022ed17          	auipc	s10,0x22e
    80002876:	6d6d0d13          	addi	s10,s10,1750 # 80230f48 <wait_lock>
    havekids = 0;
    8000287a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000287c:	0022f497          	auipc	s1,0x22f
    80002880:	ae448493          	addi	s1,s1,-1308 # 80231360 <proc>
    80002884:	a069                	j	8000290e <waitx+0xe6>
          pid = np->pid;
    80002886:	0304a983          	lw	s3,48(s1)
          *rtime = np->run_time;
    8000288a:	1a84b783          	ld	a5,424(s1)
    8000288e:	00fc2023          	sw	a5,0(s8)
          *wtime = np->end_time - np->init_time - np->run_time;
    80002892:	1b04b783          	ld	a5,432(s1)
    80002896:	1a04b703          	ld	a4,416(s1)
    8000289a:	1a84b683          	ld	a3,424(s1)
    8000289e:	9f35                	addw	a4,a4,a3
    800028a0:	9f99                	subw	a5,a5,a4
    800028a2:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7fdba340>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800028a6:	000b0e63          	beqz	s6,800028c2 <waitx+0x9a>
    800028aa:	4691                	li	a3,4
    800028ac:	02c48613          	addi	a2,s1,44
    800028b0:	85da                	mv	a1,s6
    800028b2:	05093503          	ld	a0,80(s2)
    800028b6:	fffff097          	auipc	ra,0xfffff
    800028ba:	ef4080e7          	jalr	-268(ra) # 800017aa <copyout>
    800028be:	02054563          	bltz	a0,800028e8 <waitx+0xc0>
          freeproc(np);
    800028c2:	8526                	mv	a0,s1
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	772080e7          	jalr	1906(ra) # 80002036 <freeproc>
          release(&np->lock);
    800028cc:	8526                	mv	a0,s1
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	510080e7          	jalr	1296(ra) # 80000dde <release>
          release(&wait_lock);
    800028d6:	0022e517          	auipc	a0,0x22e
    800028da:	67250513          	addi	a0,a0,1650 # 80230f48 <wait_lock>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	500080e7          	jalr	1280(ra) # 80000dde <release>
          return pid;
    800028e6:	a09d                	j	8000294c <waitx+0x124>
            release(&np->lock);
    800028e8:	8526                	mv	a0,s1
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	4f4080e7          	jalr	1268(ra) # 80000dde <release>
            release(&wait_lock);
    800028f2:	0022e517          	auipc	a0,0x22e
    800028f6:	65650513          	addi	a0,a0,1622 # 80230f48 <wait_lock>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	4e4080e7          	jalr	1252(ra) # 80000dde <release>
            return -1;
    80002902:	59fd                	li	s3,-1
    80002904:	a0a1                	j	8000294c <waitx+0x124>
    for (np = proc; np < &proc[NPROC]; np++)
    80002906:	1c848493          	addi	s1,s1,456
    8000290a:	03348463          	beq	s1,s3,80002932 <waitx+0x10a>
      if (np->parent == p)
    8000290e:	7c9c                	ld	a5,56(s1)
    80002910:	ff279be3          	bne	a5,s2,80002906 <waitx+0xde>
        acquire(&np->lock);
    80002914:	8526                	mv	a0,s1
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	414080e7          	jalr	1044(ra) # 80000d2a <acquire>
        if (np->state == ZOMBIE)
    8000291e:	4c9c                	lw	a5,24(s1)
    80002920:	f74783e3          	beq	a5,s4,80002886 <waitx+0x5e>
        release(&np->lock);
    80002924:	8526                	mv	a0,s1
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	4b8080e7          	jalr	1208(ra) # 80000dde <release>
        havekids = 1;
    8000292e:	8756                	mv	a4,s5
    80002930:	bfd9                	j	80002906 <waitx+0xde>
    if (!havekids || p->killed)
    80002932:	c701                	beqz	a4,8000293a <waitx+0x112>
    80002934:	02892783          	lw	a5,40(s2)
    80002938:	cb8d                	beqz	a5,8000296a <waitx+0x142>
      release(&wait_lock);
    8000293a:	0022e517          	auipc	a0,0x22e
    8000293e:	60e50513          	addi	a0,a0,1550 # 80230f48 <wait_lock>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	49c080e7          	jalr	1180(ra) # 80000dde <release>
      return -1;
    8000294a:	59fd                	li	s3,-1
}
    8000294c:	854e                	mv	a0,s3
    8000294e:	60e6                	ld	ra,88(sp)
    80002950:	6446                	ld	s0,80(sp)
    80002952:	64a6                	ld	s1,72(sp)
    80002954:	6906                	ld	s2,64(sp)
    80002956:	79e2                	ld	s3,56(sp)
    80002958:	7a42                	ld	s4,48(sp)
    8000295a:	7aa2                	ld	s5,40(sp)
    8000295c:	7b02                	ld	s6,32(sp)
    8000295e:	6be2                	ld	s7,24(sp)
    80002960:	6c42                	ld	s8,16(sp)
    80002962:	6ca2                	ld	s9,8(sp)
    80002964:	6d02                	ld	s10,0(sp)
    80002966:	6125                	addi	sp,sp,96
    80002968:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000296a:	85ea                	mv	a1,s10
    8000296c:	854a                	mv	a0,s2
    8000296e:	00000097          	auipc	ra,0x0
    80002972:	d2e080e7          	jalr	-722(ra) # 8000269c <sleep>
    havekids = 0;
    80002976:	b711                	j	8000287a <waitx+0x52>

0000000080002978 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002978:	7139                	addi	sp,sp,-64
    8000297a:	fc06                	sd	ra,56(sp)
    8000297c:	f822                	sd	s0,48(sp)
    8000297e:	f426                	sd	s1,40(sp)
    80002980:	f04a                	sd	s2,32(sp)
    80002982:	ec4e                	sd	s3,24(sp)
    80002984:	e852                	sd	s4,16(sp)
    80002986:	e456                	sd	s5,8(sp)
    80002988:	0080                	addi	s0,sp,64
    8000298a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000298c:	0022f497          	auipc	s1,0x22f
    80002990:	9d448493          	addi	s1,s1,-1580 # 80231360 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002994:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002996:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002998:	00236917          	auipc	s2,0x236
    8000299c:	bc890913          	addi	s2,s2,-1080 # 80238560 <mt>
    800029a0:	a821                	j	800029b8 <wakeup+0x40>
        p->state = RUNNABLE;
    800029a2:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800029a6:	8526                	mv	a0,s1
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	436080e7          	jalr	1078(ra) # 80000dde <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800029b0:	1c848493          	addi	s1,s1,456
    800029b4:	03248463          	beq	s1,s2,800029dc <wakeup+0x64>
    if (p != myproc())
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	3a6080e7          	jalr	934(ra) # 80001d5e <myproc>
    800029c0:	fea488e3          	beq	s1,a0,800029b0 <wakeup+0x38>
      acquire(&p->lock);
    800029c4:	8526                	mv	a0,s1
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	364080e7          	jalr	868(ra) # 80000d2a <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800029ce:	4c9c                	lw	a5,24(s1)
    800029d0:	fd379be3          	bne	a5,s3,800029a6 <wakeup+0x2e>
    800029d4:	709c                	ld	a5,32(s1)
    800029d6:	fd4798e3          	bne	a5,s4,800029a6 <wakeup+0x2e>
    800029da:	b7e1                	j	800029a2 <wakeup+0x2a>
    }
  }
}
    800029dc:	70e2                	ld	ra,56(sp)
    800029de:	7442                	ld	s0,48(sp)
    800029e0:	74a2                	ld	s1,40(sp)
    800029e2:	7902                	ld	s2,32(sp)
    800029e4:	69e2                	ld	s3,24(sp)
    800029e6:	6a42                	ld	s4,16(sp)
    800029e8:	6aa2                	ld	s5,8(sp)
    800029ea:	6121                	addi	sp,sp,64
    800029ec:	8082                	ret

00000000800029ee <reparent>:
{
    800029ee:	7179                	addi	sp,sp,-48
    800029f0:	f406                	sd	ra,40(sp)
    800029f2:	f022                	sd	s0,32(sp)
    800029f4:	ec26                	sd	s1,24(sp)
    800029f6:	e84a                	sd	s2,16(sp)
    800029f8:	e44e                	sd	s3,8(sp)
    800029fa:	e052                	sd	s4,0(sp)
    800029fc:	1800                	addi	s0,sp,48
    800029fe:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a00:	0022f497          	auipc	s1,0x22f
    80002a04:	96048493          	addi	s1,s1,-1696 # 80231360 <proc>
      pp->parent = initproc;
    80002a08:	00006a17          	auipc	s4,0x6
    80002a0c:	2b0a0a13          	addi	s4,s4,688 # 80008cb8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a10:	00236997          	auipc	s3,0x236
    80002a14:	b5098993          	addi	s3,s3,-1200 # 80238560 <mt>
    80002a18:	a029                	j	80002a22 <reparent+0x34>
    80002a1a:	1c848493          	addi	s1,s1,456
    80002a1e:	01348d63          	beq	s1,s3,80002a38 <reparent+0x4a>
    if (pp->parent == p)
    80002a22:	7c9c                	ld	a5,56(s1)
    80002a24:	ff279be3          	bne	a5,s2,80002a1a <reparent+0x2c>
      pp->parent = initproc;
    80002a28:	000a3503          	ld	a0,0(s4)
    80002a2c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	f4a080e7          	jalr	-182(ra) # 80002978 <wakeup>
    80002a36:	b7d5                	j	80002a1a <reparent+0x2c>
}
    80002a38:	70a2                	ld	ra,40(sp)
    80002a3a:	7402                	ld	s0,32(sp)
    80002a3c:	64e2                	ld	s1,24(sp)
    80002a3e:	6942                	ld	s2,16(sp)
    80002a40:	69a2                	ld	s3,8(sp)
    80002a42:	6a02                	ld	s4,0(sp)
    80002a44:	6145                	addi	sp,sp,48
    80002a46:	8082                	ret

0000000080002a48 <exit>:
{
    80002a48:	7179                	addi	sp,sp,-48
    80002a4a:	f406                	sd	ra,40(sp)
    80002a4c:	f022                	sd	s0,32(sp)
    80002a4e:	ec26                	sd	s1,24(sp)
    80002a50:	e84a                	sd	s2,16(sp)
    80002a52:	e44e                	sd	s3,8(sp)
    80002a54:	e052                	sd	s4,0(sp)
    80002a56:	1800                	addi	s0,sp,48
    80002a58:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	304080e7          	jalr	772(ra) # 80001d5e <myproc>
    80002a62:	89aa                	mv	s3,a0
  if (p == initproc)
    80002a64:	00006797          	auipc	a5,0x6
    80002a68:	2547b783          	ld	a5,596(a5) # 80008cb8 <initproc>
    80002a6c:	0d050493          	addi	s1,a0,208
    80002a70:	15050913          	addi	s2,a0,336
    80002a74:	02a79363          	bne	a5,a0,80002a9a <exit+0x52>
    panic("init exiting");
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	8a850513          	addi	a0,a0,-1880 # 80008320 <digits+0x2e0>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	ac4080e7          	jalr	-1340(ra) # 80000544 <panic>
      fileclose(f);
    80002a88:	00002097          	auipc	ra,0x2
    80002a8c:	57e080e7          	jalr	1406(ra) # 80005006 <fileclose>
      p->ofile[fd] = 0;
    80002a90:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002a94:	04a1                	addi	s1,s1,8
    80002a96:	01248563          	beq	s1,s2,80002aa0 <exit+0x58>
    if (p->ofile[fd])
    80002a9a:	6088                	ld	a0,0(s1)
    80002a9c:	f575                	bnez	a0,80002a88 <exit+0x40>
    80002a9e:	bfdd                	j	80002a94 <exit+0x4c>
  begin_op();
    80002aa0:	00002097          	auipc	ra,0x2
    80002aa4:	09a080e7          	jalr	154(ra) # 80004b3a <begin_op>
  iput(p->cwd);
    80002aa8:	1509b503          	ld	a0,336(s3)
    80002aac:	00002097          	auipc	ra,0x2
    80002ab0:	886080e7          	jalr	-1914(ra) # 80004332 <iput>
  end_op();
    80002ab4:	00002097          	auipc	ra,0x2
    80002ab8:	106080e7          	jalr	262(ra) # 80004bba <end_op>
  p->cwd = 0;
    80002abc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002ac0:	0022e497          	auipc	s1,0x22e
    80002ac4:	48848493          	addi	s1,s1,1160 # 80230f48 <wait_lock>
    80002ac8:	8526                	mv	a0,s1
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	260080e7          	jalr	608(ra) # 80000d2a <acquire>
  reparent(p);
    80002ad2:	854e                	mv	a0,s3
    80002ad4:	00000097          	auipc	ra,0x0
    80002ad8:	f1a080e7          	jalr	-230(ra) # 800029ee <reparent>
  wakeup(p->parent);
    80002adc:	0389b503          	ld	a0,56(s3)
    80002ae0:	00000097          	auipc	ra,0x0
    80002ae4:	e98080e7          	jalr	-360(ra) # 80002978 <wakeup>
  acquire(&p->lock);
    80002ae8:	854e                	mv	a0,s3
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	240080e7          	jalr	576(ra) # 80000d2a <acquire>
  p->xstate = status;
    80002af2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002af6:	4795                	li	a5,5
    80002af8:	00f9ac23          	sw	a5,24(s3)
  p->end_time = ticks;
    80002afc:	00006797          	auipc	a5,0x6
    80002b00:	1c47e783          	lwu	a5,452(a5) # 80008cc0 <ticks>
    80002b04:	1af9b823          	sd	a5,432(s3)
  release(&wait_lock);
    80002b08:	8526                	mv	a0,s1
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	2d4080e7          	jalr	724(ra) # 80000dde <release>
  sched();
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	a78080e7          	jalr	-1416(ra) # 8000258a <sched>
  panic("zombie exit");
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	81650513          	addi	a0,a0,-2026 # 80008330 <digits+0x2f0>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a22080e7          	jalr	-1502(ra) # 80000544 <panic>

0000000080002b2a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002b2a:	7179                	addi	sp,sp,-48
    80002b2c:	f406                	sd	ra,40(sp)
    80002b2e:	f022                	sd	s0,32(sp)
    80002b30:	ec26                	sd	s1,24(sp)
    80002b32:	e84a                	sd	s2,16(sp)
    80002b34:	e44e                	sd	s3,8(sp)
    80002b36:	1800                	addi	s0,sp,48
    80002b38:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002b3a:	0022f497          	auipc	s1,0x22f
    80002b3e:	82648493          	addi	s1,s1,-2010 # 80231360 <proc>
    80002b42:	00236997          	auipc	s3,0x236
    80002b46:	a1e98993          	addi	s3,s3,-1506 # 80238560 <mt>
  {
    acquire(&p->lock);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	1de080e7          	jalr	478(ra) # 80000d2a <acquire>
    if (p->pid == pid)
    80002b54:	589c                	lw	a5,48(s1)
    80002b56:	01278d63          	beq	a5,s2,80002b70 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002b5a:	8526                	mv	a0,s1
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	282080e7          	jalr	642(ra) # 80000dde <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b64:	1c848493          	addi	s1,s1,456
    80002b68:	ff3491e3          	bne	s1,s3,80002b4a <kill+0x20>
  }
  return -1;
    80002b6c:	557d                	li	a0,-1
    80002b6e:	a829                	j	80002b88 <kill+0x5e>
      p->killed = 1;
    80002b70:	4785                	li	a5,1
    80002b72:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002b74:	4c98                	lw	a4,24(s1)
    80002b76:	4789                	li	a5,2
    80002b78:	00f70f63          	beq	a4,a5,80002b96 <kill+0x6c>
      release(&p->lock);
    80002b7c:	8526                	mv	a0,s1
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	260080e7          	jalr	608(ra) # 80000dde <release>
      return 0;
    80002b86:	4501                	li	a0,0
}
    80002b88:	70a2                	ld	ra,40(sp)
    80002b8a:	7402                	ld	s0,32(sp)
    80002b8c:	64e2                	ld	s1,24(sp)
    80002b8e:	6942                	ld	s2,16(sp)
    80002b90:	69a2                	ld	s3,8(sp)
    80002b92:	6145                	addi	sp,sp,48
    80002b94:	8082                	ret
        p->state = RUNNABLE;
    80002b96:	478d                	li	a5,3
    80002b98:	cc9c                	sw	a5,24(s1)
    80002b9a:	b7cd                	j	80002b7c <kill+0x52>

0000000080002b9c <setkilled>:

void setkilled(struct proc *p)
{
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	e426                	sd	s1,8(sp)
    80002ba4:	1000                	addi	s0,sp,32
    80002ba6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	182080e7          	jalr	386(ra) # 80000d2a <acquire>
  p->killed = 1;
    80002bb0:	4785                	li	a5,1
    80002bb2:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002bb4:	8526                	mv	a0,s1
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	228080e7          	jalr	552(ra) # 80000dde <release>
}
    80002bbe:	60e2                	ld	ra,24(sp)
    80002bc0:	6442                	ld	s0,16(sp)
    80002bc2:	64a2                	ld	s1,8(sp)
    80002bc4:	6105                	addi	sp,sp,32
    80002bc6:	8082                	ret

0000000080002bc8 <killed>:

int killed(struct proc *p)
{
    80002bc8:	1101                	addi	sp,sp,-32
    80002bca:	ec06                	sd	ra,24(sp)
    80002bcc:	e822                	sd	s0,16(sp)
    80002bce:	e426                	sd	s1,8(sp)
    80002bd0:	e04a                	sd	s2,0(sp)
    80002bd2:	1000                	addi	s0,sp,32
    80002bd4:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	154080e7          	jalr	340(ra) # 80000d2a <acquire>
  k = p->killed;
    80002bde:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002be2:	8526                	mv	a0,s1
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	1fa080e7          	jalr	506(ra) # 80000dde <release>
  return k;
}
    80002bec:	854a                	mv	a0,s2
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6902                	ld	s2,0(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret

0000000080002bfa <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002bfa:	7179                	addi	sp,sp,-48
    80002bfc:	f406                	sd	ra,40(sp)
    80002bfe:	f022                	sd	s0,32(sp)
    80002c00:	ec26                	sd	s1,24(sp)
    80002c02:	e84a                	sd	s2,16(sp)
    80002c04:	e44e                	sd	s3,8(sp)
    80002c06:	e052                	sd	s4,0(sp)
    80002c08:	1800                	addi	s0,sp,48
    80002c0a:	84aa                	mv	s1,a0
    80002c0c:	892e                	mv	s2,a1
    80002c0e:	89b2                	mv	s3,a2
    80002c10:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	14c080e7          	jalr	332(ra) # 80001d5e <myproc>
  if (user_dst)
    80002c1a:	c08d                	beqz	s1,80002c3c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002c1c:	86d2                	mv	a3,s4
    80002c1e:	864e                	mv	a2,s3
    80002c20:	85ca                	mv	a1,s2
    80002c22:	6928                	ld	a0,80(a0)
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	b86080e7          	jalr	-1146(ra) # 800017aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002c2c:	70a2                	ld	ra,40(sp)
    80002c2e:	7402                	ld	s0,32(sp)
    80002c30:	64e2                	ld	s1,24(sp)
    80002c32:	6942                	ld	s2,16(sp)
    80002c34:	69a2                	ld	s3,8(sp)
    80002c36:	6a02                	ld	s4,0(sp)
    80002c38:	6145                	addi	sp,sp,48
    80002c3a:	8082                	ret
    memmove((char *)dst, src, len);
    80002c3c:	000a061b          	sext.w	a2,s4
    80002c40:	85ce                	mv	a1,s3
    80002c42:	854a                	mv	a0,s2
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	242080e7          	jalr	578(ra) # 80000e86 <memmove>
    return 0;
    80002c4c:	8526                	mv	a0,s1
    80002c4e:	bff9                	j	80002c2c <either_copyout+0x32>

0000000080002c50 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c50:	7179                	addi	sp,sp,-48
    80002c52:	f406                	sd	ra,40(sp)
    80002c54:	f022                	sd	s0,32(sp)
    80002c56:	ec26                	sd	s1,24(sp)
    80002c58:	e84a                	sd	s2,16(sp)
    80002c5a:	e44e                	sd	s3,8(sp)
    80002c5c:	e052                	sd	s4,0(sp)
    80002c5e:	1800                	addi	s0,sp,48
    80002c60:	892a                	mv	s2,a0
    80002c62:	84ae                	mv	s1,a1
    80002c64:	89b2                	mv	s3,a2
    80002c66:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	0f6080e7          	jalr	246(ra) # 80001d5e <myproc>
  if (user_src)
    80002c70:	c08d                	beqz	s1,80002c92 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002c72:	86d2                	mv	a3,s4
    80002c74:	864e                	mv	a2,s3
    80002c76:	85ca                	mv	a1,s2
    80002c78:	6928                	ld	a0,80(a0)
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	c10080e7          	jalr	-1008(ra) # 8000188a <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002c82:	70a2                	ld	ra,40(sp)
    80002c84:	7402                	ld	s0,32(sp)
    80002c86:	64e2                	ld	s1,24(sp)
    80002c88:	6942                	ld	s2,16(sp)
    80002c8a:	69a2                	ld	s3,8(sp)
    80002c8c:	6a02                	ld	s4,0(sp)
    80002c8e:	6145                	addi	sp,sp,48
    80002c90:	8082                	ret
    memmove(dst, (char *)src, len);
    80002c92:	000a061b          	sext.w	a2,s4
    80002c96:	85ce                	mv	a1,s3
    80002c98:	854a                	mv	a0,s2
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	1ec080e7          	jalr	492(ra) # 80000e86 <memmove>
    return 0;
    80002ca2:	8526                	mv	a0,s1
    80002ca4:	bff9                	j	80002c82 <either_copyin+0x32>

0000000080002ca6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002ca6:	715d                	addi	sp,sp,-80
    80002ca8:	e486                	sd	ra,72(sp)
    80002caa:	e0a2                	sd	s0,64(sp)
    80002cac:	fc26                	sd	s1,56(sp)
    80002cae:	f84a                	sd	s2,48(sp)
    80002cb0:	f44e                	sd	s3,40(sp)
    80002cb2:	f052                	sd	s4,32(sp)
    80002cb4:	ec56                	sd	s5,24(sp)
    80002cb6:	e85a                	sd	s6,16(sp)
    80002cb8:	e45e                	sd	s7,8(sp)
    80002cba:	0880                	addi	s0,sp,80
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;
  printf("\n");
    80002cbc:	00006517          	auipc	a0,0x6
    80002cc0:	88450513          	addi	a0,a0,-1916 # 80008540 <states.1862+0x1a8>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	8ca080e7          	jalr	-1846(ra) # 8000058e <printf>

  for (p = proc; p < &proc[NPROC]; p++)
    80002ccc:	0022e497          	auipc	s1,0x22e
    80002cd0:	7ec48493          	addi	s1,s1,2028 # 802314b8 <proc+0x158>
    80002cd4:	00236917          	auipc	s2,0x236
    80002cd8:	9e490913          	addi	s2,s2,-1564 # 802386b8 <mt+0x158>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cdc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002cde:	00005997          	auipc	s3,0x5
    80002ce2:	66298993          	addi	s3,s3,1634 # 80008340 <digits+0x300>
    printf("%d %s %s", p->pid, state, p->name);
    80002ce6:	00005a97          	auipc	s5,0x5
    80002cea:	662a8a93          	addi	s5,s5,1634 # 80008348 <digits+0x308>
    printf("\n");
    80002cee:	00006a17          	auipc	s4,0x6
    80002cf2:	852a0a13          	addi	s4,s4,-1966 # 80008540 <states.1862+0x1a8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cf6:	00005b97          	auipc	s7,0x5
    80002cfa:	692b8b93          	addi	s7,s7,1682 # 80008388 <mag01.1607>
    80002cfe:	a00d                	j	80002d20 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002d00:	ed86a583          	lw	a1,-296(a3)
    80002d04:	8556                	mv	a0,s5
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	888080e7          	jalr	-1912(ra) # 8000058e <printf>
    printf("\n");
    80002d0e:	8552                	mv	a0,s4
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	87e080e7          	jalr	-1922(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002d18:	1c848493          	addi	s1,s1,456
    80002d1c:	03248163          	beq	s1,s2,80002d3e <procdump+0x98>
    if (p->state == UNUSED)
    80002d20:	86a6                	mv	a3,s1
    80002d22:	ec04a783          	lw	a5,-320(s1)
    80002d26:	dbed                	beqz	a5,80002d18 <procdump+0x72>
      state = "???";
    80002d28:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d2a:	fcfb6be3          	bltu	s6,a5,80002d00 <procdump+0x5a>
    80002d2e:	1782                	slli	a5,a5,0x20
    80002d30:	9381                	srli	a5,a5,0x20
    80002d32:	078e                	slli	a5,a5,0x3
    80002d34:	97de                	add	a5,a5,s7
    80002d36:	6b90                	ld	a2,16(a5)
    80002d38:	f661                	bnez	a2,80002d00 <procdump+0x5a>
      state = "???";
    80002d3a:	864e                	mv	a2,s3
    80002d3c:	b7d1                	j	80002d00 <procdump+0x5a>
#ifdef LBS
    printf("%d %s %sc%d\n", p->pid, state, p->name, p->tickets);
#endif
#endif
  }
}
    80002d3e:	60a6                	ld	ra,72(sp)
    80002d40:	6406                	ld	s0,64(sp)
    80002d42:	74e2                	ld	s1,56(sp)
    80002d44:	7942                	ld	s2,48(sp)
    80002d46:	79a2                	ld	s3,40(sp)
    80002d48:	7a02                	ld	s4,32(sp)
    80002d4a:	6ae2                	ld	s5,24(sp)
    80002d4c:	6b42                	ld	s6,16(sp)
    80002d4e:	6ba2                	ld	s7,8(sp)
    80002d50:	6161                	addi	sp,sp,80
    80002d52:	8082                	ret

0000000080002d54 <swtch>:
    80002d54:	00153023          	sd	ra,0(a0)
    80002d58:	00253423          	sd	sp,8(a0)
    80002d5c:	e900                	sd	s0,16(a0)
    80002d5e:	ed04                	sd	s1,24(a0)
    80002d60:	03253023          	sd	s2,32(a0)
    80002d64:	03353423          	sd	s3,40(a0)
    80002d68:	03453823          	sd	s4,48(a0)
    80002d6c:	03553c23          	sd	s5,56(a0)
    80002d70:	05653023          	sd	s6,64(a0)
    80002d74:	05753423          	sd	s7,72(a0)
    80002d78:	05853823          	sd	s8,80(a0)
    80002d7c:	05953c23          	sd	s9,88(a0)
    80002d80:	07a53023          	sd	s10,96(a0)
    80002d84:	07b53423          	sd	s11,104(a0)
    80002d88:	0005b083          	ld	ra,0(a1)
    80002d8c:	0085b103          	ld	sp,8(a1)
    80002d90:	6980                	ld	s0,16(a1)
    80002d92:	6d84                	ld	s1,24(a1)
    80002d94:	0205b903          	ld	s2,32(a1)
    80002d98:	0285b983          	ld	s3,40(a1)
    80002d9c:	0305ba03          	ld	s4,48(a1)
    80002da0:	0385ba83          	ld	s5,56(a1)
    80002da4:	0405bb03          	ld	s6,64(a1)
    80002da8:	0485bb83          	ld	s7,72(a1)
    80002dac:	0505bc03          	ld	s8,80(a1)
    80002db0:	0585bc83          	ld	s9,88(a1)
    80002db4:	0605bd03          	ld	s10,96(a1)
    80002db8:	0685bd83          	ld	s11,104(a1)
    80002dbc:	8082                	ret

0000000080002dbe <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002dbe:	1141                	addi	sp,sp,-16
    80002dc0:	e406                	sd	ra,8(sp)
    80002dc2:	e022                	sd	s0,0(sp)
    80002dc4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002dc6:	00005597          	auipc	a1,0x5
    80002dca:	60258593          	addi	a1,a1,1538 # 800083c8 <states.1862+0x30>
    80002dce:	00237517          	auipc	a0,0x237
    80002dd2:	b1250513          	addi	a0,a0,-1262 # 802398e0 <tickslock>
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	ec4080e7          	jalr	-316(ra) # 80000c9a <initlock>
}
    80002dde:	60a2                	ld	ra,8(sp)
    80002de0:	6402                	ld	s0,0(sp)
    80002de2:	0141                	addi	sp,sp,16
    80002de4:	8082                	ret

0000000080002de6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002de6:	1141                	addi	sp,sp,-16
    80002de8:	e422                	sd	s0,8(sp)
    80002dea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dec:	00004797          	auipc	a5,0x4
    80002df0:	85478793          	addi	a5,a5,-1964 # 80006640 <kernelvec>
    80002df4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002df8:	6422                	ld	s0,8(sp)
    80002dfa:	0141                	addi	sp,sp,16
    80002dfc:	8082                	ret

0000000080002dfe <cowfault>:

int cowfault(pagetable_t pagetable, uint64 va)
{
  if (va >= MAXVA)
    80002dfe:	57fd                	li	a5,-1
    80002e00:	83e9                	srli	a5,a5,0x1a
    80002e02:	08b7e263          	bltu	a5,a1,80002e86 <cowfault+0x88>
{
    80002e06:	7179                	addi	sp,sp,-48
    80002e08:	f406                	sd	ra,40(sp)
    80002e0a:	f022                	sd	s0,32(sp)
    80002e0c:	ec26                	sd	s1,24(sp)
    80002e0e:	e84a                	sd	s2,16(sp)
    80002e10:	e44e                	sd	s3,8(sp)
    80002e12:	1800                	addi	s0,sp,48
  {
    return -1;
  }

  pte_t *pte = walk(pagetable, va, 0);
    80002e14:	4601                	li	a2,0
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	2fc080e7          	jalr	764(ra) # 80001112 <walk>
    80002e1e:	89aa                	mv	s3,a0
  if (0 == pte)
    80002e20:	c52d                	beqz	a0,80002e8a <cowfault+0x8c>
  {
    return -1;
  }

  if (0 == (*pte & PTE_U) || 0 == (*pte & PTE_V))
    80002e22:	610c                	ld	a1,0(a0)
    80002e24:	0115f713          	andi	a4,a1,17
    80002e28:	47c5                	li	a5,17
    80002e2a:	06f71263          	bne	a4,a5,80002e8e <cowfault+0x90>
  {
    return -1;
  }

  uint64 pa1 = PTE2PA(*pte);
    80002e2e:	81a9                	srli	a1,a1,0xa
    80002e30:	00c59913          	slli	s2,a1,0xc
  uint64 pa2 = (uint64)kalloc();
    80002e34:	ffffe097          	auipc	ra,0xffffe
    80002e38:	dc8080e7          	jalr	-568(ra) # 80000bfc <kalloc>
    80002e3c:	84aa                	mv	s1,a0
  if (0 == pa2)
    80002e3e:	c915                	beqz	a0,80002e72 <cowfault+0x74>
  {
    printf("cow kalloc failed\n");
    return -1;
  }

  memmove((void *)pa2, (void *)pa1, PGSIZE);
    80002e40:	6605                	lui	a2,0x1
    80002e42:	85ca                	mv	a1,s2
    80002e44:	ffffe097          	auipc	ra,0xffffe
    80002e48:	042080e7          	jalr	66(ra) # 80000e86 <memmove>

  kfree((void *)pa1);
    80002e4c:	854a                	mv	a0,s2
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	c2c080e7          	jalr	-980(ra) # 80000a7a <kfree>

  *pte = PA2PTE(pa2) | PTE_V | PTE_U | PTE_R | PTE_W | PTE_X;
    80002e56:	80b1                	srli	s1,s1,0xc
    80002e58:	04aa                	slli	s1,s1,0xa
    80002e5a:	01f4e493          	ori	s1,s1,31
    80002e5e:	0099b023          	sd	s1,0(s3)

  return 0;
    80002e62:	4501                	li	a0,0
}
    80002e64:	70a2                	ld	ra,40(sp)
    80002e66:	7402                	ld	s0,32(sp)
    80002e68:	64e2                	ld	s1,24(sp)
    80002e6a:	6942                	ld	s2,16(sp)
    80002e6c:	69a2                	ld	s3,8(sp)
    80002e6e:	6145                	addi	sp,sp,48
    80002e70:	8082                	ret
    printf("cow kalloc failed\n");
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	55e50513          	addi	a0,a0,1374 # 800083d0 <states.1862+0x38>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	714080e7          	jalr	1812(ra) # 8000058e <printf>
    return -1;
    80002e82:	557d                	li	a0,-1
    80002e84:	b7c5                	j	80002e64 <cowfault+0x66>
    return -1;
    80002e86:	557d                	li	a0,-1
}
    80002e88:	8082                	ret
    return -1;
    80002e8a:	557d                	li	a0,-1
    80002e8c:	bfe1                	j	80002e64 <cowfault+0x66>
    return -1;
    80002e8e:	557d                	li	a0,-1
    80002e90:	bfd1                	j	80002e64 <cowfault+0x66>

0000000080002e92 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002e92:	1141                	addi	sp,sp,-16
    80002e94:	e406                	sd	ra,8(sp)
    80002e96:	e022                	sd	s0,0(sp)
    80002e98:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	ec4080e7          	jalr	-316(ra) # 80001d5e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ea6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ea8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002eac:	00004617          	auipc	a2,0x4
    80002eb0:	15460613          	addi	a2,a2,340 # 80007000 <_trampoline>
    80002eb4:	00004697          	auipc	a3,0x4
    80002eb8:	14c68693          	addi	a3,a3,332 # 80007000 <_trampoline>
    80002ebc:	8e91                	sub	a3,a3,a2
    80002ebe:	040007b7          	lui	a5,0x4000
    80002ec2:	17fd                	addi	a5,a5,-1
    80002ec4:	07b2                	slli	a5,a5,0xc
    80002ec6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ec8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ecc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ece:	180026f3          	csrr	a3,satp
    80002ed2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ed4:	6d38                	ld	a4,88(a0)
    80002ed6:	6134                	ld	a3,64(a0)
    80002ed8:	6585                	lui	a1,0x1
    80002eda:	96ae                	add	a3,a3,a1
    80002edc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ede:	6d38                	ld	a4,88(a0)
    80002ee0:	00000697          	auipc	a3,0x0
    80002ee4:	13068693          	addi	a3,a3,304 # 80003010 <usertrap>
    80002ee8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002eea:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002eec:	8692                	mv	a3,tp
    80002eee:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ef0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ef4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ef8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002efc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002f00:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f02:	6f18                	ld	a4,24(a4)
    80002f04:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f08:	6928                	ld	a0,80(a0)
    80002f0a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002f0c:	00004717          	auipc	a4,0x4
    80002f10:	19070713          	addi	a4,a4,400 # 8000709c <userret>
    80002f14:	8f11                	sub	a4,a4,a2
    80002f16:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002f18:	577d                	li	a4,-1
    80002f1a:	177e                	slli	a4,a4,0x3f
    80002f1c:	8d59                	or	a0,a0,a4
    80002f1e:	9782                	jalr	a5
}
    80002f20:	60a2                	ld	ra,8(sp)
    80002f22:	6402                	ld	s0,0(sp)
    80002f24:	0141                	addi	sp,sp,16
    80002f26:	8082                	ret

0000000080002f28 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002f28:	1101                	addi	sp,sp,-32
    80002f2a:	ec06                	sd	ra,24(sp)
    80002f2c:	e822                	sd	s0,16(sp)
    80002f2e:	e426                	sd	s1,8(sp)
    80002f30:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002f32:	00237497          	auipc	s1,0x237
    80002f36:	9ae48493          	addi	s1,s1,-1618 # 802398e0 <tickslock>
    80002f3a:	8526                	mv	a0,s1
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	dee080e7          	jalr	-530(ra) # 80000d2a <acquire>
  ticks++;
    80002f44:	00006517          	auipc	a0,0x6
    80002f48:	d7c50513          	addi	a0,a0,-644 # 80008cc0 <ticks>
    80002f4c:	411c                	lw	a5,0(a0)
    80002f4e:	2785                	addiw	a5,a5,1
    80002f50:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	a26080e7          	jalr	-1498(ra) # 80002978 <wakeup>
  release(&tickslock);
    80002f5a:	8526                	mv	a0,s1
    80002f5c:	ffffe097          	auipc	ra,0xffffe
    80002f60:	e82080e7          	jalr	-382(ra) # 80000dde <release>
}
    80002f64:	60e2                	ld	ra,24(sp)
    80002f66:	6442                	ld	s0,16(sp)
    80002f68:	64a2                	ld	s1,8(sp)
    80002f6a:	6105                	addi	sp,sp,32
    80002f6c:	8082                	ret

0000000080002f6e <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002f6e:	1101                	addi	sp,sp,-32
    80002f70:	ec06                	sd	ra,24(sp)
    80002f72:	e822                	sd	s0,16(sp)
    80002f74:	e426                	sd	s1,8(sp)
    80002f76:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f78:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002f7c:	00074d63          	bltz	a4,80002f96 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002f80:	57fd                	li	a5,-1
    80002f82:	17fe                	slli	a5,a5,0x3f
    80002f84:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002f86:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002f88:	06f70363          	beq	a4,a5,80002fee <devintr+0x80>
  }
}
    80002f8c:	60e2                	ld	ra,24(sp)
    80002f8e:	6442                	ld	s0,16(sp)
    80002f90:	64a2                	ld	s1,8(sp)
    80002f92:	6105                	addi	sp,sp,32
    80002f94:	8082                	ret
      (scause & 0xff) == 9)
    80002f96:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002f9a:	46a5                	li	a3,9
    80002f9c:	fed792e3          	bne	a5,a3,80002f80 <devintr+0x12>
    int irq = plic_claim();
    80002fa0:	00003097          	auipc	ra,0x3
    80002fa4:	7a8080e7          	jalr	1960(ra) # 80006748 <plic_claim>
    80002fa8:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002faa:	47a9                	li	a5,10
    80002fac:	02f50763          	beq	a0,a5,80002fda <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002fb0:	4785                	li	a5,1
    80002fb2:	02f50963          	beq	a0,a5,80002fe4 <devintr+0x76>
    return 1;
    80002fb6:	4505                	li	a0,1
    else if (irq)
    80002fb8:	d8f1                	beqz	s1,80002f8c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002fba:	85a6                	mv	a1,s1
    80002fbc:	00005517          	auipc	a0,0x5
    80002fc0:	42c50513          	addi	a0,a0,1068 # 800083e8 <states.1862+0x50>
    80002fc4:	ffffd097          	auipc	ra,0xffffd
    80002fc8:	5ca080e7          	jalr	1482(ra) # 8000058e <printf>
      plic_complete(irq);
    80002fcc:	8526                	mv	a0,s1
    80002fce:	00003097          	auipc	ra,0x3
    80002fd2:	79e080e7          	jalr	1950(ra) # 8000676c <plic_complete>
    return 1;
    80002fd6:	4505                	li	a0,1
    80002fd8:	bf55                	j	80002f8c <devintr+0x1e>
      uartintr();
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	9d4080e7          	jalr	-1580(ra) # 800009ae <uartintr>
    80002fe2:	b7ed                	j	80002fcc <devintr+0x5e>
      virtio_disk_intr();
    80002fe4:	00004097          	auipc	ra,0x4
    80002fe8:	cb2080e7          	jalr	-846(ra) # 80006c96 <virtio_disk_intr>
    80002fec:	b7c5                	j	80002fcc <devintr+0x5e>
    if (cpuid() == 0)
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	d44080e7          	jalr	-700(ra) # 80001d32 <cpuid>
    80002ff6:	c901                	beqz	a0,80003006 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ff8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ffc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ffe:	14479073          	csrw	sip,a5
    return 2;
    80003002:	4509                	li	a0,2
    80003004:	b761                	j	80002f8c <devintr+0x1e>
      clockintr();
    80003006:	00000097          	auipc	ra,0x0
    8000300a:	f22080e7          	jalr	-222(ra) # 80002f28 <clockintr>
    8000300e:	b7ed                	j	80002ff8 <devintr+0x8a>

0000000080003010 <usertrap>:
{
    80003010:	1101                	addi	sp,sp,-32
    80003012:	ec06                	sd	ra,24(sp)
    80003014:	e822                	sd	s0,16(sp)
    80003016:	e426                	sd	s1,8(sp)
    80003018:	e04a                	sd	s2,0(sp)
    8000301a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000301c:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80003020:	1007f793          	andi	a5,a5,256
    80003024:	efad                	bnez	a5,8000309e <usertrap+0x8e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003026:	00003797          	auipc	a5,0x3
    8000302a:	61a78793          	addi	a5,a5,1562 # 80006640 <kernelvec>
    8000302e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003032:	fffff097          	auipc	ra,0xfffff
    80003036:	d2c080e7          	jalr	-724(ra) # 80001d5e <myproc>
    8000303a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000303c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000303e:	14102773          	csrr	a4,sepc
    80003042:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003044:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80003048:	47a1                	li	a5,8
    8000304a:	06f70263          	beq	a4,a5,800030ae <usertrap+0x9e>
  else if ((which_dev = devintr()) != 0)
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	f20080e7          	jalr	-224(ra) # 80002f6e <devintr>
    80003056:	892a                	mv	s2,a0
    80003058:	e161                	bnez	a0,80003118 <usertrap+0x108>
    8000305a:	14202773          	csrr	a4,scause
  else if (0xf == r_scause())
    8000305e:	47bd                	li	a5,15
    80003060:	0af70063          	beq	a4,a5,80003100 <usertrap+0xf0>
    80003064:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003068:	5890                	lw	a2,48(s1)
    8000306a:	00005517          	auipc	a0,0x5
    8000306e:	3be50513          	addi	a0,a0,958 # 80008428 <states.1862+0x90>
    80003072:	ffffd097          	auipc	ra,0xffffd
    80003076:	51c080e7          	jalr	1308(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000307a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000307e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003082:	00005517          	auipc	a0,0x5
    80003086:	3d650513          	addi	a0,a0,982 # 80008458 <states.1862+0xc0>
    8000308a:	ffffd097          	auipc	ra,0xffffd
    8000308e:	504080e7          	jalr	1284(ra) # 8000058e <printf>
    setkilled(p);
    80003092:	8526                	mv	a0,s1
    80003094:	00000097          	auipc	ra,0x0
    80003098:	b08080e7          	jalr	-1272(ra) # 80002b9c <setkilled>
    8000309c:	a825                	j	800030d4 <usertrap+0xc4>
    panic("usertrap: not from user mode");
    8000309e:	00005517          	auipc	a0,0x5
    800030a2:	36a50513          	addi	a0,a0,874 # 80008408 <states.1862+0x70>
    800030a6:	ffffd097          	auipc	ra,0xffffd
    800030aa:	49e080e7          	jalr	1182(ra) # 80000544 <panic>
    if (killed(p))
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	b1a080e7          	jalr	-1254(ra) # 80002bc8 <killed>
    800030b6:	ed1d                	bnez	a0,800030f4 <usertrap+0xe4>
    p->trapframe->epc += 4;
    800030b8:	6cb8                	ld	a4,88(s1)
    800030ba:	6f1c                	ld	a5,24(a4)
    800030bc:	0791                	addi	a5,a5,4
    800030be:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030c0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800030c4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030c8:	10079073          	csrw	sstatus,a5
    syscall();
    800030cc:	00000097          	auipc	ra,0x0
    800030d0:	31c080e7          	jalr	796(ra) # 800033e8 <syscall>
  if (killed(p))
    800030d4:	8526                	mv	a0,s1
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	af2080e7          	jalr	-1294(ra) # 80002bc8 <killed>
    800030de:	e521                	bnez	a0,80003126 <usertrap+0x116>
  usertrapret();
    800030e0:	00000097          	auipc	ra,0x0
    800030e4:	db2080e7          	jalr	-590(ra) # 80002e92 <usertrapret>
}
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	64a2                	ld	s1,8(sp)
    800030ee:	6902                	ld	s2,0(sp)
    800030f0:	6105                	addi	sp,sp,32
    800030f2:	8082                	ret
      exit(-1);
    800030f4:	557d                	li	a0,-1
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	952080e7          	jalr	-1710(ra) # 80002a48 <exit>
    800030fe:	bf6d                	j	800030b8 <usertrap+0xa8>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003100:	143025f3          	csrr	a1,stval
    if (0 > cowfault(p->pagetable, r_stval()))
    80003104:	68a8                	ld	a0,80(s1)
    80003106:	00000097          	auipc	ra,0x0
    8000310a:	cf8080e7          	jalr	-776(ra) # 80002dfe <cowfault>
    8000310e:	fc0553e3          	bgez	a0,800030d4 <usertrap+0xc4>
      p->killed = 1;
    80003112:	4785                	li	a5,1
    80003114:	d49c                	sw	a5,40(s1)
    80003116:	bf7d                	j	800030d4 <usertrap+0xc4>
  if (killed(p))
    80003118:	8526                	mv	a0,s1
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	aae080e7          	jalr	-1362(ra) # 80002bc8 <killed>
    80003122:	c901                	beqz	a0,80003132 <usertrap+0x122>
    80003124:	a011                	j	80003128 <usertrap+0x118>
    80003126:	4901                	li	s2,0
    exit(-1);
    80003128:	557d                	li	a0,-1
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	91e080e7          	jalr	-1762(ra) # 80002a48 <exit>
  if (which_dev == 2)
    80003132:	4789                	li	a5,2
    80003134:	faf916e3          	bne	s2,a5,800030e0 <usertrap+0xd0>
    p->completed_clockval = p->completed_clockval + 1;
    80003138:	17c4a783          	lw	a5,380(s1)
    8000313c:	2785                	addiw	a5,a5,1
    8000313e:	0007871b          	sext.w	a4,a5
    80003142:	16f4ae23          	sw	a5,380(s1)
    if (p->clockval > 0 && p->clockval <= p->completed_clockval)
    80003146:	1784a783          	lw	a5,376(s1)
    8000314a:	04f05663          	blez	a5,80003196 <usertrap+0x186>
    8000314e:	04f74463          	blt	a4,a5,80003196 <usertrap+0x186>
      if (p->is_sigalarm == 0)
    80003152:	1744a783          	lw	a5,372(s1)
    80003156:	e3a1                	bnez	a5,80003196 <usertrap+0x186>
        p->is_sigalarm = 1;
    80003158:	4785                	li	a5,1
    8000315a:	16f4aa23          	sw	a5,372(s1)
        p->completed_clockval = 0;
    8000315e:	1604ae23          	sw	zero,380(s1)
        *(p->cpy_trapframe) = *(p->trapframe);
    80003162:	6cb4                	ld	a3,88(s1)
    80003164:	87b6                	mv	a5,a3
    80003166:	1904b703          	ld	a4,400(s1)
    8000316a:	12068693          	addi	a3,a3,288
    8000316e:	0007b803          	ld	a6,0(a5)
    80003172:	6788                	ld	a0,8(a5)
    80003174:	6b8c                	ld	a1,16(a5)
    80003176:	6f90                	ld	a2,24(a5)
    80003178:	01073023          	sd	a6,0(a4)
    8000317c:	e708                	sd	a0,8(a4)
    8000317e:	eb0c                	sd	a1,16(a4)
    80003180:	ef10                	sd	a2,24(a4)
    80003182:	02078793          	addi	a5,a5,32
    80003186:	02070713          	addi	a4,a4,32
    8000318a:	fed792e3          	bne	a5,a3,8000316e <usertrap+0x15e>
        p->trapframe->epc = p->handler;
    8000318e:	6cbc                	ld	a5,88(s1)
    80003190:	1804b703          	ld	a4,384(s1)
    80003194:	ef98                	sd	a4,24(a5)
    yield();
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	4ca080e7          	jalr	1226(ra) # 80002660 <yield>
    8000319e:	b789                	j	800030e0 <usertrap+0xd0>

00000000800031a0 <kerneltrap>:
{
    800031a0:	7179                	addi	sp,sp,-48
    800031a2:	f406                	sd	ra,40(sp)
    800031a4:	f022                	sd	s0,32(sp)
    800031a6:	ec26                	sd	s1,24(sp)
    800031a8:	e84a                	sd	s2,16(sp)
    800031aa:	e44e                	sd	s3,8(sp)
    800031ac:	e052                	sd	s4,0(sp)
    800031ae:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800031b0:	fffff097          	auipc	ra,0xfffff
    800031b4:	bae080e7          	jalr	-1106(ra) # 80001d5e <myproc>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031b8:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031bc:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031c0:	14202a73          	csrr	s4,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800031c4:	10097793          	andi	a5,s2,256
    800031c8:	cb95                	beqz	a5,800031fc <kerneltrap+0x5c>
    800031ca:	84aa                	mv	s1,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031cc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031d0:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800031d2:	ef8d                	bnez	a5,8000320c <kerneltrap+0x6c>
  if ((which_dev = devintr()) == 0)
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	d9a080e7          	jalr	-614(ra) # 80002f6e <devintr>
    800031dc:	c121                	beqz	a0,8000321c <kerneltrap+0x7c>
  if (which_dev == 2 && p != 0 && p->state == RUNNING)
    800031de:	4789                	li	a5,2
    800031e0:	06f50b63          	beq	a0,a5,80003256 <kerneltrap+0xb6>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031e4:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031e8:	10091073          	csrw	sstatus,s2
}
    800031ec:	70a2                	ld	ra,40(sp)
    800031ee:	7402                	ld	s0,32(sp)
    800031f0:	64e2                	ld	s1,24(sp)
    800031f2:	6942                	ld	s2,16(sp)
    800031f4:	69a2                	ld	s3,8(sp)
    800031f6:	6a02                	ld	s4,0(sp)
    800031f8:	6145                	addi	sp,sp,48
    800031fa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031fc:	00005517          	auipc	a0,0x5
    80003200:	27c50513          	addi	a0,a0,636 # 80008478 <states.1862+0xe0>
    80003204:	ffffd097          	auipc	ra,0xffffd
    80003208:	340080e7          	jalr	832(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    8000320c:	00005517          	auipc	a0,0x5
    80003210:	29450513          	addi	a0,a0,660 # 800084a0 <states.1862+0x108>
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	330080e7          	jalr	816(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    8000321c:	85d2                	mv	a1,s4
    8000321e:	00005517          	auipc	a0,0x5
    80003222:	2a250513          	addi	a0,a0,674 # 800084c0 <states.1862+0x128>
    80003226:	ffffd097          	auipc	ra,0xffffd
    8000322a:	368080e7          	jalr	872(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000322e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003232:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003236:	00005517          	auipc	a0,0x5
    8000323a:	29a50513          	addi	a0,a0,666 # 800084d0 <states.1862+0x138>
    8000323e:	ffffd097          	auipc	ra,0xffffd
    80003242:	350080e7          	jalr	848(ra) # 8000058e <printf>
    panic("kerneltrap");
    80003246:	00005517          	auipc	a0,0x5
    8000324a:	2a250513          	addi	a0,a0,674 # 800084e8 <states.1862+0x150>
    8000324e:	ffffd097          	auipc	ra,0xffffd
    80003252:	2f6080e7          	jalr	758(ra) # 80000544 <panic>
  if (which_dev == 2 && p != 0 && p->state == RUNNING)
    80003256:	d4d9                	beqz	s1,800031e4 <kerneltrap+0x44>
    80003258:	4c98                	lw	a4,24(s1)
    8000325a:	4791                	li	a5,4
    8000325c:	f8f714e3          	bne	a4,a5,800031e4 <kerneltrap+0x44>
    yield();
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	400080e7          	jalr	1024(ra) # 80002660 <yield>
    80003268:	bfb5                	j	800031e4 <kerneltrap+0x44>

000000008000326a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000326a:	1101                	addi	sp,sp,-32
    8000326c:	ec06                	sd	ra,24(sp)
    8000326e:	e822                	sd	s0,16(sp)
    80003270:	e426                	sd	s1,8(sp)
    80003272:	1000                	addi	s0,sp,32
    80003274:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003276:	fffff097          	auipc	ra,0xfffff
    8000327a:	ae8080e7          	jalr	-1304(ra) # 80001d5e <myproc>
  switch (n)
    8000327e:	4795                	li	a5,5
    80003280:	0497e163          	bltu	a5,s1,800032c2 <argraw+0x58>
    80003284:	048a                	slli	s1,s1,0x2
    80003286:	00005717          	auipc	a4,0x5
    8000328a:	42270713          	addi	a4,a4,1058 # 800086a8 <states.1862+0x310>
    8000328e:	94ba                	add	s1,s1,a4
    80003290:	409c                	lw	a5,0(s1)
    80003292:	97ba                	add	a5,a5,a4
    80003294:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80003296:	6d3c                	ld	a5,88(a0)
    80003298:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	64a2                	ld	s1,8(sp)
    800032a0:	6105                	addi	sp,sp,32
    800032a2:	8082                	ret
    return p->trapframe->a1;
    800032a4:	6d3c                	ld	a5,88(a0)
    800032a6:	7fa8                	ld	a0,120(a5)
    800032a8:	bfcd                	j	8000329a <argraw+0x30>
    return p->trapframe->a2;
    800032aa:	6d3c                	ld	a5,88(a0)
    800032ac:	63c8                	ld	a0,128(a5)
    800032ae:	b7f5                	j	8000329a <argraw+0x30>
    return p->trapframe->a3;
    800032b0:	6d3c                	ld	a5,88(a0)
    800032b2:	67c8                	ld	a0,136(a5)
    800032b4:	b7dd                	j	8000329a <argraw+0x30>
    return p->trapframe->a4;
    800032b6:	6d3c                	ld	a5,88(a0)
    800032b8:	6bc8                	ld	a0,144(a5)
    800032ba:	b7c5                	j	8000329a <argraw+0x30>
    return p->trapframe->a5;
    800032bc:	6d3c                	ld	a5,88(a0)
    800032be:	6fc8                	ld	a0,152(a5)
    800032c0:	bfe9                	j	8000329a <argraw+0x30>
  panic("argraw");
    800032c2:	00005517          	auipc	a0,0x5
    800032c6:	23650513          	addi	a0,a0,566 # 800084f8 <states.1862+0x160>
    800032ca:	ffffd097          	auipc	ra,0xffffd
    800032ce:	27a080e7          	jalr	634(ra) # 80000544 <panic>

00000000800032d2 <fetchaddr>:
{
    800032d2:	1101                	addi	sp,sp,-32
    800032d4:	ec06                	sd	ra,24(sp)
    800032d6:	e822                	sd	s0,16(sp)
    800032d8:	e426                	sd	s1,8(sp)
    800032da:	e04a                	sd	s2,0(sp)
    800032dc:	1000                	addi	s0,sp,32
    800032de:	84aa                	mv	s1,a0
    800032e0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800032e2:	fffff097          	auipc	ra,0xfffff
    800032e6:	a7c080e7          	jalr	-1412(ra) # 80001d5e <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800032ea:	653c                	ld	a5,72(a0)
    800032ec:	02f4f863          	bgeu	s1,a5,8000331c <fetchaddr+0x4a>
    800032f0:	00848713          	addi	a4,s1,8
    800032f4:	02e7e663          	bltu	a5,a4,80003320 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800032f8:	46a1                	li	a3,8
    800032fa:	8626                	mv	a2,s1
    800032fc:	85ca                	mv	a1,s2
    800032fe:	6928                	ld	a0,80(a0)
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	58a080e7          	jalr	1418(ra) # 8000188a <copyin>
    80003308:	00a03533          	snez	a0,a0
    8000330c:	40a00533          	neg	a0,a0
}
    80003310:	60e2                	ld	ra,24(sp)
    80003312:	6442                	ld	s0,16(sp)
    80003314:	64a2                	ld	s1,8(sp)
    80003316:	6902                	ld	s2,0(sp)
    80003318:	6105                	addi	sp,sp,32
    8000331a:	8082                	ret
    return -1;
    8000331c:	557d                	li	a0,-1
    8000331e:	bfcd                	j	80003310 <fetchaddr+0x3e>
    80003320:	557d                	li	a0,-1
    80003322:	b7fd                	j	80003310 <fetchaddr+0x3e>

0000000080003324 <fetchstr>:
{
    80003324:	7179                	addi	sp,sp,-48
    80003326:	f406                	sd	ra,40(sp)
    80003328:	f022                	sd	s0,32(sp)
    8000332a:	ec26                	sd	s1,24(sp)
    8000332c:	e84a                	sd	s2,16(sp)
    8000332e:	e44e                	sd	s3,8(sp)
    80003330:	1800                	addi	s0,sp,48
    80003332:	892a                	mv	s2,a0
    80003334:	84ae                	mv	s1,a1
    80003336:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003338:	fffff097          	auipc	ra,0xfffff
    8000333c:	a26080e7          	jalr	-1498(ra) # 80001d5e <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003340:	86ce                	mv	a3,s3
    80003342:	864a                	mv	a2,s2
    80003344:	85a6                	mv	a1,s1
    80003346:	6928                	ld	a0,80(a0)
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	5ce080e7          	jalr	1486(ra) # 80001916 <copyinstr>
    80003350:	00054e63          	bltz	a0,8000336c <fetchstr+0x48>
  return strlen(buf);
    80003354:	8526                	mv	a0,s1
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	c54080e7          	jalr	-940(ra) # 80000faa <strlen>
}
    8000335e:	70a2                	ld	ra,40(sp)
    80003360:	7402                	ld	s0,32(sp)
    80003362:	64e2                	ld	s1,24(sp)
    80003364:	6942                	ld	s2,16(sp)
    80003366:	69a2                	ld	s3,8(sp)
    80003368:	6145                	addi	sp,sp,48
    8000336a:	8082                	ret
    return -1;
    8000336c:	557d                	li	a0,-1
    8000336e:	bfc5                	j	8000335e <fetchstr+0x3a>

0000000080003370 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003370:	1101                	addi	sp,sp,-32
    80003372:	ec06                	sd	ra,24(sp)
    80003374:	e822                	sd	s0,16(sp)
    80003376:	e426                	sd	s1,8(sp)
    80003378:	1000                	addi	s0,sp,32
    8000337a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	eee080e7          	jalr	-274(ra) # 8000326a <argraw>
    80003384:	c088                	sw	a0,0(s1)
}
    80003386:	60e2                	ld	ra,24(sp)
    80003388:	6442                	ld	s0,16(sp)
    8000338a:	64a2                	ld	s1,8(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret

0000000080003390 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003390:	1101                	addi	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	e426                	sd	s1,8(sp)
    80003398:	1000                	addi	s0,sp,32
    8000339a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	ece080e7          	jalr	-306(ra) # 8000326a <argraw>
    800033a4:	e088                	sd	a0,0(s1)
}
    800033a6:	60e2                	ld	ra,24(sp)
    800033a8:	6442                	ld	s0,16(sp)
    800033aa:	64a2                	ld	s1,8(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret

00000000800033b0 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800033b0:	7179                	addi	sp,sp,-48
    800033b2:	f406                	sd	ra,40(sp)
    800033b4:	f022                	sd	s0,32(sp)
    800033b6:	ec26                	sd	s1,24(sp)
    800033b8:	e84a                	sd	s2,16(sp)
    800033ba:	1800                	addi	s0,sp,48
    800033bc:	84ae                	mv	s1,a1
    800033be:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800033c0:	fd840593          	addi	a1,s0,-40
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	fcc080e7          	jalr	-52(ra) # 80003390 <argaddr>
  return fetchstr(addr, buf, max);
    800033cc:	864a                	mv	a2,s2
    800033ce:	85a6                	mv	a1,s1
    800033d0:	fd843503          	ld	a0,-40(s0)
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	f50080e7          	jalr	-176(ra) # 80003324 <fetchstr>
}
    800033dc:	70a2                	ld	ra,40(sp)
    800033de:	7402                	ld	s0,32(sp)
    800033e0:	64e2                	ld	s1,24(sp)
    800033e2:	6942                	ld	s2,16(sp)
    800033e4:	6145                	addi	sp,sp,48
    800033e6:	8082                	ret

00000000800033e8 <syscall>:
    [SYS_waitx] 3,
    [SYS_set_tickets] 1,
};

void syscall(void)
{
    800033e8:	7179                	addi	sp,sp,-48
    800033ea:	f406                	sd	ra,40(sp)
    800033ec:	f022                	sd	s0,32(sp)
    800033ee:	ec26                	sd	s1,24(sp)
    800033f0:	e84a                	sd	s2,16(sp)
    800033f2:	e44e                	sd	s3,8(sp)
    800033f4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800033f6:	fffff097          	auipc	ra,0xfffff
    800033fa:	968080e7          	jalr	-1688(ra) # 80001d5e <myproc>
    800033fe:	84aa                	mv	s1,a0

  int num = p->trapframe->a7;
    80003400:	05853903          	ld	s2,88(a0)
    80003404:	0a893783          	ld	a5,168(s2)
    80003408:	0007899b          	sext.w	s3,a5

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000340c:	37fd                	addiw	a5,a5,-1
    8000340e:	4769                	li	a4,26
    80003410:	12f76f63          	bltu	a4,a5,8000354e <syscall+0x166>
    80003414:	00399713          	slli	a4,s3,0x3
    80003418:	00005797          	auipc	a5,0x5
    8000341c:	2c078793          	addi	a5,a5,704 # 800086d8 <syscalls>
    80003420:	97ba                	add	a5,a5,a4
    80003422:	639c                	ld	a5,0(a5)
    80003424:	12078563          	beqz	a5,8000354e <syscall+0x166>
  {
    p->trapframe->a0 = syscalls[num]();
    80003428:	9782                	jalr	a5
    8000342a:	06a93823          	sd	a0,112(s2)

    if ((1 << p->trapframe->a7) & p->bitmask)
    8000342e:	6cbc                	ld	a5,88(s1)
    80003430:	77d8                	ld	a4,168(a5)
    80003432:	1704a783          	lw	a5,368(s1)
    80003436:	40e7d7bb          	sraw	a5,a5,a4
    8000343a:	8b85                	andi	a5,a5,1
    8000343c:	12078863          	beqz	a5,8000356c <syscall+0x184>
    {
      printf("%d: syscall %s ", p->pid, names[num]);
    80003440:	00005917          	auipc	s2,0x5
    80003444:	6f890913          	addi	s2,s2,1784 # 80008b38 <names>
    80003448:	00399793          	slli	a5,s3,0x3
    8000344c:	97ca                	add	a5,a5,s2
    8000344e:	6390                	ld	a2,0(a5)
    80003450:	588c                	lw	a1,48(s1)
    80003452:	00005517          	auipc	a0,0x5
    80003456:	0ae50513          	addi	a0,a0,174 # 80008500 <states.1862+0x168>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	134080e7          	jalr	308(ra) # 8000058e <printf>
      switch (args_num[num])
    80003462:	098a                	slli	s3,s3,0x2
    80003464:	994e                	add	s2,s2,s3
    80003466:	0e092703          	lw	a4,224(s2)
    8000346a:	4795                	li	a5,5
    8000346c:	0ae7ef63          	bltu	a5,a4,8000352a <syscall+0x142>
    80003470:	0e096783          	lwu	a5,224(s2)
    80003474:	078a                	slli	a5,a5,0x2
    80003476:	00005717          	auipc	a4,0x5
    8000347a:	24a70713          	addi	a4,a4,586 # 800086c0 <states.1862+0x328>
    8000347e:	97ba                	add	a5,a5,a4
    80003480:	439c                	lw	a5,0(a5)
    80003482:	97ba                	add	a5,a5,a4
    80003484:	8782                	jr	a5
      {
      case L0:
        printf("(%d) -> %d\n", p->trapframe->a0, p->trapframe->a0);
    80003486:	6cbc                	ld	a5,88(s1)
    80003488:	7bac                	ld	a1,112(a5)
    8000348a:	862e                	mv	a2,a1
    8000348c:	00005517          	auipc	a0,0x5
    80003490:	08450513          	addi	a0,a0,132 # 80008510 <states.1862+0x178>
    80003494:	ffffd097          	auipc	ra,0xffffd
    80003498:	0fa080e7          	jalr	250(ra) # 8000058e <printf>
        break;
    8000349c:	a8c1                	j	8000356c <syscall+0x184>
      case L1:
        printf("(%d) -> %d\n", p->trapframe->a0, p->trapframe->a0);
    8000349e:	6cbc                	ld	a5,88(s1)
    800034a0:	7bac                	ld	a1,112(a5)
    800034a2:	862e                	mv	a2,a1
    800034a4:	00005517          	auipc	a0,0x5
    800034a8:	06c50513          	addi	a0,a0,108 # 80008510 <states.1862+0x178>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	0e2080e7          	jalr	226(ra) # 8000058e <printf>
        break;
    800034b4:	a865                	j	8000356c <syscall+0x184>
      case L2:
        printf("(%d %d) -> %d\n", p->trapframe->a0, p->trapframe->a1, p->trapframe->a0);
    800034b6:	6cbc                	ld	a5,88(s1)
    800034b8:	7bac                	ld	a1,112(a5)
    800034ba:	86ae                	mv	a3,a1
    800034bc:	7fb0                	ld	a2,120(a5)
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	06250513          	addi	a0,a0,98 # 80008520 <states.1862+0x188>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	0c8080e7          	jalr	200(ra) # 8000058e <printf>
        break;
    800034ce:	a879                	j	8000356c <syscall+0x184>
      case L3:
        printf("(%d %d %d) -> %d\n", p->trapframe->a0, p->trapframe->a1, p->trapframe->a2, p->trapframe->a0);
    800034d0:	6cbc                	ld	a5,88(s1)
    800034d2:	7bac                	ld	a1,112(a5)
    800034d4:	872e                	mv	a4,a1
    800034d6:	63d4                	ld	a3,128(a5)
    800034d8:	7fb0                	ld	a2,120(a5)
    800034da:	00005517          	auipc	a0,0x5
    800034de:	05650513          	addi	a0,a0,86 # 80008530 <states.1862+0x198>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	0ac080e7          	jalr	172(ra) # 8000058e <printf>
        break;
    800034ea:	a049                	j	8000356c <syscall+0x184>
      case L4:
        printf("(%d %d %d %d) -> %d\n", p->trapframe->a0, p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a0);
    800034ec:	6cb0                	ld	a2,88(s1)
    800034ee:	7a2c                	ld	a1,112(a2)
    800034f0:	87ae                	mv	a5,a1
    800034f2:	6658                	ld	a4,136(a2)
    800034f4:	6254                	ld	a3,128(a2)
    800034f6:	7e30                	ld	a2,120(a2)
    800034f8:	00005517          	auipc	a0,0x5
    800034fc:	05050513          	addi	a0,a0,80 # 80008548 <states.1862+0x1b0>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	08e080e7          	jalr	142(ra) # 8000058e <printf>
        break;
    80003508:	a095                	j	8000356c <syscall+0x184>
      case L5:
        printf("(%d %d %d %d %d) -> %d\n", p->trapframe->a0, p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a4, p->trapframe->a0);
    8000350a:	6cb0                	ld	a2,88(s1)
    8000350c:	7a2c                	ld	a1,112(a2)
    8000350e:	882e                	mv	a6,a1
    80003510:	6a5c                	ld	a5,144(a2)
    80003512:	6658                	ld	a4,136(a2)
    80003514:	6254                	ld	a3,128(a2)
    80003516:	7e30                	ld	a2,120(a2)
    80003518:	00005517          	auipc	a0,0x5
    8000351c:	04850513          	addi	a0,a0,72 # 80008560 <states.1862+0x1c8>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	06e080e7          	jalr	110(ra) # 8000058e <printf>
        break;
    80003528:	a091                	j	8000356c <syscall+0x184>
      default:
        printf("(%d %d %d %d %d %d) -> %d\n", p->trapframe->a0, p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a4, p->trapframe->a5, p->trapframe->a0);
    8000352a:	6cb0                	ld	a2,88(s1)
    8000352c:	7a2c                	ld	a1,112(a2)
    8000352e:	88ae                	mv	a7,a1
    80003530:	09863803          	ld	a6,152(a2)
    80003534:	6a5c                	ld	a5,144(a2)
    80003536:	6658                	ld	a4,136(a2)
    80003538:	6254                	ld	a3,128(a2)
    8000353a:	7e30                	ld	a2,120(a2)
    8000353c:	00005517          	auipc	a0,0x5
    80003540:	03c50513          	addi	a0,a0,60 # 80008578 <states.1862+0x1e0>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	04a080e7          	jalr	74(ra) # 8000058e <printf>
        break;
    8000354c:	a005                	j	8000356c <syscall+0x184>
      }
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    8000354e:	86ce                	mv	a3,s3
    80003550:	15848613          	addi	a2,s1,344
    80003554:	588c                	lw	a1,48(s1)
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	04250513          	addi	a0,a0,66 # 80008598 <states.1862+0x200>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	030080e7          	jalr	48(ra) # 8000058e <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003566:	6cbc                	ld	a5,88(s1)
    80003568:	577d                	li	a4,-1
    8000356a:	fbb8                	sd	a4,112(a5)
  }
}
    8000356c:	70a2                	ld	ra,40(sp)
    8000356e:	7402                	ld	s0,32(sp)
    80003570:	64e2                	ld	s1,24(sp)
    80003572:	6942                	ld	s2,16(sp)
    80003574:	69a2                	ld	s3,8(sp)
    80003576:	6145                	addi	sp,sp,48
    80003578:	8082                	ret

000000008000357a <sys_exit>:
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64 sys_exit(void)
{
    8000357a:	1101                	addi	sp,sp,-32
    8000357c:	ec06                	sd	ra,24(sp)
    8000357e:	e822                	sd	s0,16(sp)
    80003580:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003582:	fec40593          	addi	a1,s0,-20
    80003586:	4501                	li	a0,0
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	de8080e7          	jalr	-536(ra) # 80003370 <argint>
  exit(n);
    80003590:	fec42503          	lw	a0,-20(s0)
    80003594:	fffff097          	auipc	ra,0xfffff
    80003598:	4b4080e7          	jalr	1204(ra) # 80002a48 <exit>
  return 0; // not reached
}
    8000359c:	4501                	li	a0,0
    8000359e:	60e2                	ld	ra,24(sp)
    800035a0:	6442                	ld	s0,16(sp)
    800035a2:	6105                	addi	sp,sp,32
    800035a4:	8082                	ret

00000000800035a6 <sys_getpid>:

uint64 sys_getpid(void)
{
    800035a6:	1141                	addi	sp,sp,-16
    800035a8:	e406                	sd	ra,8(sp)
    800035aa:	e022                	sd	s0,0(sp)
    800035ac:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800035ae:	ffffe097          	auipc	ra,0xffffe
    800035b2:	7b0080e7          	jalr	1968(ra) # 80001d5e <myproc>
}
    800035b6:	5908                	lw	a0,48(a0)
    800035b8:	60a2                	ld	ra,8(sp)
    800035ba:	6402                	ld	s0,0(sp)
    800035bc:	0141                	addi	sp,sp,16
    800035be:	8082                	ret

00000000800035c0 <sys_fork>:

uint64 sys_fork(void)
{
    800035c0:	1141                	addi	sp,sp,-16
    800035c2:	e406                	sd	ra,8(sp)
    800035c4:	e022                	sd	s0,0(sp)
    800035c6:	0800                	addi	s0,sp,16
  return fork();
    800035c8:	fffff097          	auipc	ra,0xfffff
    800035cc:	cea080e7          	jalr	-790(ra) # 800022b2 <fork>
}
    800035d0:	60a2                	ld	ra,8(sp)
    800035d2:	6402                	ld	s0,0(sp)
    800035d4:	0141                	addi	sp,sp,16
    800035d6:	8082                	ret

00000000800035d8 <sys_wait>:

uint64 sys_wait(void)
{
    800035d8:	1101                	addi	sp,sp,-32
    800035da:	ec06                	sd	ra,24(sp)
    800035dc:	e822                	sd	s0,16(sp)
    800035de:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800035e0:	fe840593          	addi	a1,s0,-24
    800035e4:	4501                	li	a0,0
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	daa080e7          	jalr	-598(ra) # 80003390 <argaddr>
  return wait(p);
    800035ee:	fe843503          	ld	a0,-24(s0)
    800035f2:	fffff097          	auipc	ra,0xfffff
    800035f6:	10e080e7          	jalr	270(ra) # 80002700 <wait>
}
    800035fa:	60e2                	ld	ra,24(sp)
    800035fc:	6442                	ld	s0,16(sp)
    800035fe:	6105                	addi	sp,sp,32
    80003600:	8082                	ret

0000000080003602 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003602:	7139                	addi	sp,sp,-64
    80003604:	fc06                	sd	ra,56(sp)
    80003606:	f822                	sd	s0,48(sp)
    80003608:	f426                	sd	s1,40(sp)
    8000360a:	f04a                	sd	s2,32(sp)
    8000360c:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000360e:	fd840593          	addi	a1,s0,-40
    80003612:	4501                	li	a0,0
    80003614:	00000097          	auipc	ra,0x0
    80003618:	d7c080e7          	jalr	-644(ra) # 80003390 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000361c:	fd040593          	addi	a1,s0,-48
    80003620:	4505                	li	a0,1
    80003622:	00000097          	auipc	ra,0x0
    80003626:	d6e080e7          	jalr	-658(ra) # 80003390 <argaddr>
  argaddr(2, &addr2);
    8000362a:	fc840593          	addi	a1,s0,-56
    8000362e:	4509                	li	a0,2
    80003630:	00000097          	auipc	ra,0x0
    80003634:	d60080e7          	jalr	-672(ra) # 80003390 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003638:	fc040613          	addi	a2,s0,-64
    8000363c:	fc440593          	addi	a1,s0,-60
    80003640:	fd843503          	ld	a0,-40(s0)
    80003644:	fffff097          	auipc	ra,0xfffff
    80003648:	1e4080e7          	jalr	484(ra) # 80002828 <waitx>
    8000364c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000364e:	ffffe097          	auipc	ra,0xffffe
    80003652:	710080e7          	jalr	1808(ra) # 80001d5e <myproc>
    80003656:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003658:	4691                	li	a3,4
    8000365a:	fc440613          	addi	a2,s0,-60
    8000365e:	fd043583          	ld	a1,-48(s0)
    80003662:	6928                	ld	a0,80(a0)
    80003664:	ffffe097          	auipc	ra,0xffffe
    80003668:	146080e7          	jalr	326(ra) # 800017aa <copyout>
    return -1;
    8000366c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000366e:	00054f63          	bltz	a0,8000368c <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003672:	4691                	li	a3,4
    80003674:	fc040613          	addi	a2,s0,-64
    80003678:	fc843583          	ld	a1,-56(s0)
    8000367c:	68a8                	ld	a0,80(s1)
    8000367e:	ffffe097          	auipc	ra,0xffffe
    80003682:	12c080e7          	jalr	300(ra) # 800017aa <copyout>
    80003686:	00054a63          	bltz	a0,8000369a <sys_waitx+0x98>
    return -1;
  return ret;
    8000368a:	87ca                	mv	a5,s2
}
    8000368c:	853e                	mv	a0,a5
    8000368e:	70e2                	ld	ra,56(sp)
    80003690:	7442                	ld	s0,48(sp)
    80003692:	74a2                	ld	s1,40(sp)
    80003694:	7902                	ld	s2,32(sp)
    80003696:	6121                	addi	sp,sp,64
    80003698:	8082                	ret
    return -1;
    8000369a:	57fd                	li	a5,-1
    8000369c:	bfc5                	j	8000368c <sys_waitx+0x8a>

000000008000369e <sys_sbrk>:

uint64 sys_sbrk(void)
{
    8000369e:	7179                	addi	sp,sp,-48
    800036a0:	f406                	sd	ra,40(sp)
    800036a2:	f022                	sd	s0,32(sp)
    800036a4:	ec26                	sd	s1,24(sp)
    800036a6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800036a8:	fdc40593          	addi	a1,s0,-36
    800036ac:	4501                	li	a0,0
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	cc2080e7          	jalr	-830(ra) # 80003370 <argint>
  addr = myproc()->sz;
    800036b6:	ffffe097          	auipc	ra,0xffffe
    800036ba:	6a8080e7          	jalr	1704(ra) # 80001d5e <myproc>
    800036be:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800036c0:	fdc42503          	lw	a0,-36(s0)
    800036c4:	fffff097          	auipc	ra,0xfffff
    800036c8:	b92080e7          	jalr	-1134(ra) # 80002256 <growproc>
    800036cc:	00054863          	bltz	a0,800036dc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800036d0:	8526                	mv	a0,s1
    800036d2:	70a2                	ld	ra,40(sp)
    800036d4:	7402                	ld	s0,32(sp)
    800036d6:	64e2                	ld	s1,24(sp)
    800036d8:	6145                	addi	sp,sp,48
    800036da:	8082                	ret
    return -1;
    800036dc:	54fd                	li	s1,-1
    800036de:	bfcd                	j	800036d0 <sys_sbrk+0x32>

00000000800036e0 <sys_sleep>:

uint64 sys_sleep(void)
{
    800036e0:	7139                	addi	sp,sp,-64
    800036e2:	fc06                	sd	ra,56(sp)
    800036e4:	f822                	sd	s0,48(sp)
    800036e6:	f426                	sd	s1,40(sp)
    800036e8:	f04a                	sd	s2,32(sp)
    800036ea:	ec4e                	sd	s3,24(sp)
    800036ec:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800036ee:	fcc40593          	addi	a1,s0,-52
    800036f2:	4501                	li	a0,0
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	c7c080e7          	jalr	-900(ra) # 80003370 <argint>
  acquire(&tickslock);
    800036fc:	00236517          	auipc	a0,0x236
    80003700:	1e450513          	addi	a0,a0,484 # 802398e0 <tickslock>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	626080e7          	jalr	1574(ra) # 80000d2a <acquire>
  ticks0 = ticks;
    8000370c:	00005917          	auipc	s2,0x5
    80003710:	5b492903          	lw	s2,1460(s2) # 80008cc0 <ticks>
  while (ticks - ticks0 < n)
    80003714:	fcc42783          	lw	a5,-52(s0)
    80003718:	cf9d                	beqz	a5,80003756 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000371a:	00236997          	auipc	s3,0x236
    8000371e:	1c698993          	addi	s3,s3,454 # 802398e0 <tickslock>
    80003722:	00005497          	auipc	s1,0x5
    80003726:	59e48493          	addi	s1,s1,1438 # 80008cc0 <ticks>
    if (killed(myproc()))
    8000372a:	ffffe097          	auipc	ra,0xffffe
    8000372e:	634080e7          	jalr	1588(ra) # 80001d5e <myproc>
    80003732:	fffff097          	auipc	ra,0xfffff
    80003736:	496080e7          	jalr	1174(ra) # 80002bc8 <killed>
    8000373a:	ed15                	bnez	a0,80003776 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000373c:	85ce                	mv	a1,s3
    8000373e:	8526                	mv	a0,s1
    80003740:	fffff097          	auipc	ra,0xfffff
    80003744:	f5c080e7          	jalr	-164(ra) # 8000269c <sleep>
  while (ticks - ticks0 < n)
    80003748:	409c                	lw	a5,0(s1)
    8000374a:	412787bb          	subw	a5,a5,s2
    8000374e:	fcc42703          	lw	a4,-52(s0)
    80003752:	fce7ece3          	bltu	a5,a4,8000372a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003756:	00236517          	auipc	a0,0x236
    8000375a:	18a50513          	addi	a0,a0,394 # 802398e0 <tickslock>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	680080e7          	jalr	1664(ra) # 80000dde <release>
  return 0;
    80003766:	4501                	li	a0,0
}
    80003768:	70e2                	ld	ra,56(sp)
    8000376a:	7442                	ld	s0,48(sp)
    8000376c:	74a2                	ld	s1,40(sp)
    8000376e:	7902                	ld	s2,32(sp)
    80003770:	69e2                	ld	s3,24(sp)
    80003772:	6121                	addi	sp,sp,64
    80003774:	8082                	ret
      release(&tickslock);
    80003776:	00236517          	auipc	a0,0x236
    8000377a:	16a50513          	addi	a0,a0,362 # 802398e0 <tickslock>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	660080e7          	jalr	1632(ra) # 80000dde <release>
      return -1;
    80003786:	557d                	li	a0,-1
    80003788:	b7c5                	j	80003768 <sys_sleep+0x88>

000000008000378a <sys_kill>:

uint64 sys_kill(void)
{
    8000378a:	1101                	addi	sp,sp,-32
    8000378c:	ec06                	sd	ra,24(sp)
    8000378e:	e822                	sd	s0,16(sp)
    80003790:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003792:	fec40593          	addi	a1,s0,-20
    80003796:	4501                	li	a0,0
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	bd8080e7          	jalr	-1064(ra) # 80003370 <argint>
  return kill(pid);
    800037a0:	fec42503          	lw	a0,-20(s0)
    800037a4:	fffff097          	auipc	ra,0xfffff
    800037a8:	386080e7          	jalr	902(ra) # 80002b2a <kill>
}
    800037ac:	60e2                	ld	ra,24(sp)
    800037ae:	6442                	ld	s0,16(sp)
    800037b0:	6105                	addi	sp,sp,32
    800037b2:	8082                	ret

00000000800037b4 <sys_uptime>:

uint64 sys_uptime(void)
{
    800037b4:	1101                	addi	sp,sp,-32
    800037b6:	ec06                	sd	ra,24(sp)
    800037b8:	e822                	sd	s0,16(sp)
    800037ba:	e426                	sd	s1,8(sp)
    800037bc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800037be:	00236517          	auipc	a0,0x236
    800037c2:	12250513          	addi	a0,a0,290 # 802398e0 <tickslock>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	564080e7          	jalr	1380(ra) # 80000d2a <acquire>
  xticks = ticks;
    800037ce:	00005497          	auipc	s1,0x5
    800037d2:	4f24a483          	lw	s1,1266(s1) # 80008cc0 <ticks>
  release(&tickslock);
    800037d6:	00236517          	auipc	a0,0x236
    800037da:	10a50513          	addi	a0,a0,266 # 802398e0 <tickslock>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	600080e7          	jalr	1536(ra) # 80000dde <release>
  return xticks;
}
    800037e6:	02049513          	slli	a0,s1,0x20
    800037ea:	9101                	srli	a0,a0,0x20
    800037ec:	60e2                	ld	ra,24(sp)
    800037ee:	6442                	ld	s0,16(sp)
    800037f0:	64a2                	ld	s1,8(sp)
    800037f2:	6105                	addi	sp,sp,32
    800037f4:	8082                	ret

00000000800037f6 <sys_trace>:

uint64 sys_trace(void)
{
    800037f6:	1141                	addi	sp,sp,-16
    800037f8:	e406                	sd	ra,8(sp)
    800037fa:	e022                	sd	s0,0(sp)
    800037fc:	0800                	addi	s0,sp,16
  argint(0, &myproc()->bitmask);
    800037fe:	ffffe097          	auipc	ra,0xffffe
    80003802:	560080e7          	jalr	1376(ra) # 80001d5e <myproc>
    80003806:	17050593          	addi	a1,a0,368
    8000380a:	4501                	li	a0,0
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	b64080e7          	jalr	-1180(ra) # 80003370 <argint>
  return 0;
}
    80003814:	4501                	li	a0,0
    80003816:	60a2                	ld	ra,8(sp)
    80003818:	6402                	ld	s0,0(sp)
    8000381a:	0141                	addi	sp,sp,16
    8000381c:	8082                	ret

000000008000381e <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    8000381e:	1101                	addi	sp,sp,-32
    80003820:	ec06                	sd	ra,24(sp)
    80003822:	e822                	sd	s0,16(sp)
    80003824:	e426                	sd	s1,8(sp)
    80003826:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003828:	ffffe097          	auipc	ra,0xffffe
    8000382c:	536080e7          	jalr	1334(ra) # 80001d5e <myproc>
    80003830:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->cpy_trapframe, sizeof(*(p->trapframe)));
    80003832:	12000613          	li	a2,288
    80003836:	19053583          	ld	a1,400(a0)
    8000383a:	6d28                	ld	a0,88(a0)
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	64a080e7          	jalr	1610(ra) # 80000e86 <memmove>

  p->completed_clockval = 0;
    80003844:	1604ae23          	sw	zero,380(s1)
  p->is_sigalarm = 0;
    80003848:	1604aa23          	sw	zero,372(s1)

  // printf("* handler is %d\n", handler)
  // printf("~ clockval is %d\n", curr_clockval);

  usertrapret();
    8000384c:	fffff097          	auipc	ra,0xfffff
    80003850:	646080e7          	jalr	1606(ra) # 80002e92 <usertrapret>
  return 0;
}
    80003854:	4501                	li	a0,0
    80003856:	60e2                	ld	ra,24(sp)
    80003858:	6442                	ld	s0,16(sp)
    8000385a:	64a2                	ld	s1,8(sp)
    8000385c:	6105                	addi	sp,sp,32
    8000385e:	8082                	ret

0000000080003860 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80003860:	7179                	addi	sp,sp,-48
    80003862:	f406                	sd	ra,40(sp)
    80003864:	f022                	sd	s0,32(sp)
    80003866:	ec26                	sd	s1,24(sp)
    80003868:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000386a:	ffffe097          	auipc	ra,0xffffe
    8000386e:	4f4080e7          	jalr	1268(ra) # 80001d5e <myproc>
    80003872:	84aa                	mv	s1,a0
  int curr_clockval;
  argint(0, &curr_clockval);
    80003874:	fdc40593          	addi	a1,s0,-36
    80003878:	4501                	li	a0,0
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	af6080e7          	jalr	-1290(ra) # 80003370 <argint>

  uint64 curr_handler;
  argaddr(1, &curr_handler);
    80003882:	fd040593          	addi	a1,s0,-48
    80003886:	4505                	li	a0,1
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	b08080e7          	jalr	-1272(ra) # 80003390 <argaddr>

  // printf("* handler is %d\n", curr_handler);
  // printf("~ clockval is %d\n", curr_clockval);

  p->is_sigalarm = 0;
    80003890:	1604aa23          	sw	zero,372(s1)
  p->completed_clockval = 0;
    80003894:	1604ae23          	sw	zero,380(s1)

  p->clockval = curr_clockval;
    80003898:	fdc42783          	lw	a5,-36(s0)
    8000389c:	16f4ac23          	sw	a5,376(s1)
  p->handler = curr_handler; // to store the handler function address
    800038a0:	fd043783          	ld	a5,-48(s0)
    800038a4:	18f4b023          	sd	a5,384(s1)
  return 0;
}
    800038a8:	4501                	li	a0,0
    800038aa:	70a2                	ld	ra,40(sp)
    800038ac:	7402                	ld	s0,32(sp)
    800038ae:	64e2                	ld	s1,24(sp)
    800038b0:	6145                	addi	sp,sp,48
    800038b2:	8082                	ret

00000000800038b4 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800038b4:	1141                	addi	sp,sp,-16
    800038b6:	e422                	sd	s0,8(sp)
    800038b8:	0800                	addi	s0,sp,16
  // #if defined(FCFS) || defined(ROUNDROBIN)
  //   printf("Wrong scheduler\n");
  //   return 0;
  // #endif
  return 0;
}
    800038ba:	4501                	li	a0,0
    800038bc:	6422                	ld	s0,8(sp)
    800038be:	0141                	addi	sp,sp,16
    800038c0:	8082                	ret

00000000800038c2 <sys_set_tickets>:

uint64
sys_set_tickets(void)
{
    800038c2:	1141                	addi	sp,sp,-16
    800038c4:	e422                	sd	s0,8(sp)
    800038c6:	0800                	addi	s0,sp,16

  return change;
#endif

  return 0;
    800038c8:	4501                	li	a0,0
    800038ca:	6422                	ld	s0,8(sp)
    800038cc:	0141                	addi	sp,sp,16
    800038ce:	8082                	ret

00000000800038d0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800038d0:	7179                	addi	sp,sp,-48
    800038d2:	f406                	sd	ra,40(sp)
    800038d4:	f022                	sd	s0,32(sp)
    800038d6:	ec26                	sd	s1,24(sp)
    800038d8:	e84a                	sd	s2,16(sp)
    800038da:	e44e                	sd	s3,8(sp)
    800038dc:	e052                	sd	s4,0(sp)
    800038de:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800038e0:	00005597          	auipc	a1,0x5
    800038e4:	ed858593          	addi	a1,a1,-296 # 800087b8 <syscalls+0xe0>
    800038e8:	00236517          	auipc	a0,0x236
    800038ec:	01050513          	addi	a0,a0,16 # 802398f8 <bcache>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	3aa080e7          	jalr	938(ra) # 80000c9a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800038f8:	0023e797          	auipc	a5,0x23e
    800038fc:	00078793          	mv	a5,a5
    80003900:	0023e717          	auipc	a4,0x23e
    80003904:	26070713          	addi	a4,a4,608 # 80241b60 <bcache+0x8268>
    80003908:	2ae7b823          	sd	a4,688(a5) # 80241ba8 <bcache+0x82b0>
  bcache.head.next = &bcache.head;
    8000390c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003910:	00236497          	auipc	s1,0x236
    80003914:	00048493          	mv	s1,s1
    b->next = bcache.head.next;
    80003918:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000391a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000391c:	00005a17          	auipc	s4,0x5
    80003920:	ea4a0a13          	addi	s4,s4,-348 # 800087c0 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003924:	2b893783          	ld	a5,696(s2)
    80003928:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000392a:	0534b423          	sd	s3,72(s1) # 80239958 <bcache+0x60>
    initsleeplock(&b->lock, "buffer");
    8000392e:	85d2                	mv	a1,s4
    80003930:	01048513          	addi	a0,s1,16
    80003934:	00001097          	auipc	ra,0x1
    80003938:	4c4080e7          	jalr	1220(ra) # 80004df8 <initsleeplock>
    bcache.head.next->prev = b;
    8000393c:	2b893783          	ld	a5,696(s2)
    80003940:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003942:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003946:	45848493          	addi	s1,s1,1112
    8000394a:	fd349de3          	bne	s1,s3,80003924 <binit+0x54>
  }
}
    8000394e:	70a2                	ld	ra,40(sp)
    80003950:	7402                	ld	s0,32(sp)
    80003952:	64e2                	ld	s1,24(sp)
    80003954:	6942                	ld	s2,16(sp)
    80003956:	69a2                	ld	s3,8(sp)
    80003958:	6a02                	ld	s4,0(sp)
    8000395a:	6145                	addi	sp,sp,48
    8000395c:	8082                	ret

000000008000395e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000395e:	7179                	addi	sp,sp,-48
    80003960:	f406                	sd	ra,40(sp)
    80003962:	f022                	sd	s0,32(sp)
    80003964:	ec26                	sd	s1,24(sp)
    80003966:	e84a                	sd	s2,16(sp)
    80003968:	e44e                	sd	s3,8(sp)
    8000396a:	1800                	addi	s0,sp,48
    8000396c:	89aa                	mv	s3,a0
    8000396e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003970:	00236517          	auipc	a0,0x236
    80003974:	f8850513          	addi	a0,a0,-120 # 802398f8 <bcache>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	3b2080e7          	jalr	946(ra) # 80000d2a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003980:	0023e497          	auipc	s1,0x23e
    80003984:	2304b483          	ld	s1,560(s1) # 80241bb0 <bcache+0x82b8>
    80003988:	0023e797          	auipc	a5,0x23e
    8000398c:	1d878793          	addi	a5,a5,472 # 80241b60 <bcache+0x8268>
    80003990:	02f48f63          	beq	s1,a5,800039ce <bread+0x70>
    80003994:	873e                	mv	a4,a5
    80003996:	a021                	j	8000399e <bread+0x40>
    80003998:	68a4                	ld	s1,80(s1)
    8000399a:	02e48a63          	beq	s1,a4,800039ce <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000399e:	449c                	lw	a5,8(s1)
    800039a0:	ff379ce3          	bne	a5,s3,80003998 <bread+0x3a>
    800039a4:	44dc                	lw	a5,12(s1)
    800039a6:	ff2799e3          	bne	a5,s2,80003998 <bread+0x3a>
      b->refcnt++;
    800039aa:	40bc                	lw	a5,64(s1)
    800039ac:	2785                	addiw	a5,a5,1
    800039ae:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800039b0:	00236517          	auipc	a0,0x236
    800039b4:	f4850513          	addi	a0,a0,-184 # 802398f8 <bcache>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	426080e7          	jalr	1062(ra) # 80000dde <release>
      acquiresleep(&b->lock);
    800039c0:	01048513          	addi	a0,s1,16
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	46e080e7          	jalr	1134(ra) # 80004e32 <acquiresleep>
      return b;
    800039cc:	a8b9                	j	80003a2a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039ce:	0023e497          	auipc	s1,0x23e
    800039d2:	1da4b483          	ld	s1,474(s1) # 80241ba8 <bcache+0x82b0>
    800039d6:	0023e797          	auipc	a5,0x23e
    800039da:	18a78793          	addi	a5,a5,394 # 80241b60 <bcache+0x8268>
    800039de:	00f48863          	beq	s1,a5,800039ee <bread+0x90>
    800039e2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800039e4:	40bc                	lw	a5,64(s1)
    800039e6:	cf81                	beqz	a5,800039fe <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039e8:	64a4                	ld	s1,72(s1)
    800039ea:	fee49de3          	bne	s1,a4,800039e4 <bread+0x86>
  panic("bget: no buffers");
    800039ee:	00005517          	auipc	a0,0x5
    800039f2:	dda50513          	addi	a0,a0,-550 # 800087c8 <syscalls+0xf0>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	b4e080e7          	jalr	-1202(ra) # 80000544 <panic>
      b->dev = dev;
    800039fe:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003a02:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003a06:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003a0a:	4785                	li	a5,1
    80003a0c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a0e:	00236517          	auipc	a0,0x236
    80003a12:	eea50513          	addi	a0,a0,-278 # 802398f8 <bcache>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	3c8080e7          	jalr	968(ra) # 80000dde <release>
      acquiresleep(&b->lock);
    80003a1e:	01048513          	addi	a0,s1,16
    80003a22:	00001097          	auipc	ra,0x1
    80003a26:	410080e7          	jalr	1040(ra) # 80004e32 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003a2a:	409c                	lw	a5,0(s1)
    80003a2c:	cb89                	beqz	a5,80003a3e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003a2e:	8526                	mv	a0,s1
    80003a30:	70a2                	ld	ra,40(sp)
    80003a32:	7402                	ld	s0,32(sp)
    80003a34:	64e2                	ld	s1,24(sp)
    80003a36:	6942                	ld	s2,16(sp)
    80003a38:	69a2                	ld	s3,8(sp)
    80003a3a:	6145                	addi	sp,sp,48
    80003a3c:	8082                	ret
    virtio_disk_rw(b, 0);
    80003a3e:	4581                	li	a1,0
    80003a40:	8526                	mv	a0,s1
    80003a42:	00003097          	auipc	ra,0x3
    80003a46:	fc6080e7          	jalr	-58(ra) # 80006a08 <virtio_disk_rw>
    b->valid = 1;
    80003a4a:	4785                	li	a5,1
    80003a4c:	c09c                	sw	a5,0(s1)
  return b;
    80003a4e:	b7c5                	j	80003a2e <bread+0xd0>

0000000080003a50 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003a50:	1101                	addi	sp,sp,-32
    80003a52:	ec06                	sd	ra,24(sp)
    80003a54:	e822                	sd	s0,16(sp)
    80003a56:	e426                	sd	s1,8(sp)
    80003a58:	1000                	addi	s0,sp,32
    80003a5a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a5c:	0541                	addi	a0,a0,16
    80003a5e:	00001097          	auipc	ra,0x1
    80003a62:	46e080e7          	jalr	1134(ra) # 80004ecc <holdingsleep>
    80003a66:	cd01                	beqz	a0,80003a7e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003a68:	4585                	li	a1,1
    80003a6a:	8526                	mv	a0,s1
    80003a6c:	00003097          	auipc	ra,0x3
    80003a70:	f9c080e7          	jalr	-100(ra) # 80006a08 <virtio_disk_rw>
}
    80003a74:	60e2                	ld	ra,24(sp)
    80003a76:	6442                	ld	s0,16(sp)
    80003a78:	64a2                	ld	s1,8(sp)
    80003a7a:	6105                	addi	sp,sp,32
    80003a7c:	8082                	ret
    panic("bwrite");
    80003a7e:	00005517          	auipc	a0,0x5
    80003a82:	d6250513          	addi	a0,a0,-670 # 800087e0 <syscalls+0x108>
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	abe080e7          	jalr	-1346(ra) # 80000544 <panic>

0000000080003a8e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003a8e:	1101                	addi	sp,sp,-32
    80003a90:	ec06                	sd	ra,24(sp)
    80003a92:	e822                	sd	s0,16(sp)
    80003a94:	e426                	sd	s1,8(sp)
    80003a96:	e04a                	sd	s2,0(sp)
    80003a98:	1000                	addi	s0,sp,32
    80003a9a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a9c:	01050913          	addi	s2,a0,16
    80003aa0:	854a                	mv	a0,s2
    80003aa2:	00001097          	auipc	ra,0x1
    80003aa6:	42a080e7          	jalr	1066(ra) # 80004ecc <holdingsleep>
    80003aaa:	c92d                	beqz	a0,80003b1c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003aac:	854a                	mv	a0,s2
    80003aae:	00001097          	auipc	ra,0x1
    80003ab2:	3da080e7          	jalr	986(ra) # 80004e88 <releasesleep>

  acquire(&bcache.lock);
    80003ab6:	00236517          	auipc	a0,0x236
    80003aba:	e4250513          	addi	a0,a0,-446 # 802398f8 <bcache>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	26c080e7          	jalr	620(ra) # 80000d2a <acquire>
  b->refcnt--;
    80003ac6:	40bc                	lw	a5,64(s1)
    80003ac8:	37fd                	addiw	a5,a5,-1
    80003aca:	0007871b          	sext.w	a4,a5
    80003ace:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003ad0:	eb05                	bnez	a4,80003b00 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003ad2:	68bc                	ld	a5,80(s1)
    80003ad4:	64b8                	ld	a4,72(s1)
    80003ad6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003ad8:	64bc                	ld	a5,72(s1)
    80003ada:	68b8                	ld	a4,80(s1)
    80003adc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003ade:	0023e797          	auipc	a5,0x23e
    80003ae2:	e1a78793          	addi	a5,a5,-486 # 802418f8 <bcache+0x8000>
    80003ae6:	2b87b703          	ld	a4,696(a5)
    80003aea:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003aec:	0023e717          	auipc	a4,0x23e
    80003af0:	07470713          	addi	a4,a4,116 # 80241b60 <bcache+0x8268>
    80003af4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003af6:	2b87b703          	ld	a4,696(a5)
    80003afa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003afc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003b00:	00236517          	auipc	a0,0x236
    80003b04:	df850513          	addi	a0,a0,-520 # 802398f8 <bcache>
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	2d6080e7          	jalr	726(ra) # 80000dde <release>
}
    80003b10:	60e2                	ld	ra,24(sp)
    80003b12:	6442                	ld	s0,16(sp)
    80003b14:	64a2                	ld	s1,8(sp)
    80003b16:	6902                	ld	s2,0(sp)
    80003b18:	6105                	addi	sp,sp,32
    80003b1a:	8082                	ret
    panic("brelse");
    80003b1c:	00005517          	auipc	a0,0x5
    80003b20:	ccc50513          	addi	a0,a0,-820 # 800087e8 <syscalls+0x110>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	a20080e7          	jalr	-1504(ra) # 80000544 <panic>

0000000080003b2c <bpin>:

void
bpin(struct buf *b) {
    80003b2c:	1101                	addi	sp,sp,-32
    80003b2e:	ec06                	sd	ra,24(sp)
    80003b30:	e822                	sd	s0,16(sp)
    80003b32:	e426                	sd	s1,8(sp)
    80003b34:	1000                	addi	s0,sp,32
    80003b36:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b38:	00236517          	auipc	a0,0x236
    80003b3c:	dc050513          	addi	a0,a0,-576 # 802398f8 <bcache>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	1ea080e7          	jalr	490(ra) # 80000d2a <acquire>
  b->refcnt++;
    80003b48:	40bc                	lw	a5,64(s1)
    80003b4a:	2785                	addiw	a5,a5,1
    80003b4c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b4e:	00236517          	auipc	a0,0x236
    80003b52:	daa50513          	addi	a0,a0,-598 # 802398f8 <bcache>
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	288080e7          	jalr	648(ra) # 80000dde <release>
}
    80003b5e:	60e2                	ld	ra,24(sp)
    80003b60:	6442                	ld	s0,16(sp)
    80003b62:	64a2                	ld	s1,8(sp)
    80003b64:	6105                	addi	sp,sp,32
    80003b66:	8082                	ret

0000000080003b68 <bunpin>:

void
bunpin(struct buf *b) {
    80003b68:	1101                	addi	sp,sp,-32
    80003b6a:	ec06                	sd	ra,24(sp)
    80003b6c:	e822                	sd	s0,16(sp)
    80003b6e:	e426                	sd	s1,8(sp)
    80003b70:	1000                	addi	s0,sp,32
    80003b72:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b74:	00236517          	auipc	a0,0x236
    80003b78:	d8450513          	addi	a0,a0,-636 # 802398f8 <bcache>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	1ae080e7          	jalr	430(ra) # 80000d2a <acquire>
  b->refcnt--;
    80003b84:	40bc                	lw	a5,64(s1)
    80003b86:	37fd                	addiw	a5,a5,-1
    80003b88:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b8a:	00236517          	auipc	a0,0x236
    80003b8e:	d6e50513          	addi	a0,a0,-658 # 802398f8 <bcache>
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	24c080e7          	jalr	588(ra) # 80000dde <release>
}
    80003b9a:	60e2                	ld	ra,24(sp)
    80003b9c:	6442                	ld	s0,16(sp)
    80003b9e:	64a2                	ld	s1,8(sp)
    80003ba0:	6105                	addi	sp,sp,32
    80003ba2:	8082                	ret

0000000080003ba4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003ba4:	1101                	addi	sp,sp,-32
    80003ba6:	ec06                	sd	ra,24(sp)
    80003ba8:	e822                	sd	s0,16(sp)
    80003baa:	e426                	sd	s1,8(sp)
    80003bac:	e04a                	sd	s2,0(sp)
    80003bae:	1000                	addi	s0,sp,32
    80003bb0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003bb2:	00d5d59b          	srliw	a1,a1,0xd
    80003bb6:	0023e797          	auipc	a5,0x23e
    80003bba:	41e7a783          	lw	a5,1054(a5) # 80241fd4 <sb+0x1c>
    80003bbe:	9dbd                	addw	a1,a1,a5
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	d9e080e7          	jalr	-610(ra) # 8000395e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003bc8:	0074f713          	andi	a4,s1,7
    80003bcc:	4785                	li	a5,1
    80003bce:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003bd2:	14ce                	slli	s1,s1,0x33
    80003bd4:	90d9                	srli	s1,s1,0x36
    80003bd6:	00950733          	add	a4,a0,s1
    80003bda:	05874703          	lbu	a4,88(a4)
    80003bde:	00e7f6b3          	and	a3,a5,a4
    80003be2:	c69d                	beqz	a3,80003c10 <bfree+0x6c>
    80003be4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003be6:	94aa                	add	s1,s1,a0
    80003be8:	fff7c793          	not	a5,a5
    80003bec:	8ff9                	and	a5,a5,a4
    80003bee:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003bf2:	00001097          	auipc	ra,0x1
    80003bf6:	120080e7          	jalr	288(ra) # 80004d12 <log_write>
  brelse(bp);
    80003bfa:	854a                	mv	a0,s2
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	e92080e7          	jalr	-366(ra) # 80003a8e <brelse>
}
    80003c04:	60e2                	ld	ra,24(sp)
    80003c06:	6442                	ld	s0,16(sp)
    80003c08:	64a2                	ld	s1,8(sp)
    80003c0a:	6902                	ld	s2,0(sp)
    80003c0c:	6105                	addi	sp,sp,32
    80003c0e:	8082                	ret
    panic("freeing free block");
    80003c10:	00005517          	auipc	a0,0x5
    80003c14:	be050513          	addi	a0,a0,-1056 # 800087f0 <syscalls+0x118>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	92c080e7          	jalr	-1748(ra) # 80000544 <panic>

0000000080003c20 <balloc>:
{
    80003c20:	711d                	addi	sp,sp,-96
    80003c22:	ec86                	sd	ra,88(sp)
    80003c24:	e8a2                	sd	s0,80(sp)
    80003c26:	e4a6                	sd	s1,72(sp)
    80003c28:	e0ca                	sd	s2,64(sp)
    80003c2a:	fc4e                	sd	s3,56(sp)
    80003c2c:	f852                	sd	s4,48(sp)
    80003c2e:	f456                	sd	s5,40(sp)
    80003c30:	f05a                	sd	s6,32(sp)
    80003c32:	ec5e                	sd	s7,24(sp)
    80003c34:	e862                	sd	s8,16(sp)
    80003c36:	e466                	sd	s9,8(sp)
    80003c38:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003c3a:	0023e797          	auipc	a5,0x23e
    80003c3e:	3827a783          	lw	a5,898(a5) # 80241fbc <sb+0x4>
    80003c42:	10078163          	beqz	a5,80003d44 <balloc+0x124>
    80003c46:	8baa                	mv	s7,a0
    80003c48:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003c4a:	0023eb17          	auipc	s6,0x23e
    80003c4e:	36eb0b13          	addi	s6,s6,878 # 80241fb8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c52:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003c54:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c56:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003c58:	6c89                	lui	s9,0x2
    80003c5a:	a061                	j	80003ce2 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003c5c:	974a                	add	a4,a4,s2
    80003c5e:	8fd5                	or	a5,a5,a3
    80003c60:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003c64:	854a                	mv	a0,s2
    80003c66:	00001097          	auipc	ra,0x1
    80003c6a:	0ac080e7          	jalr	172(ra) # 80004d12 <log_write>
        brelse(bp);
    80003c6e:	854a                	mv	a0,s2
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	e1e080e7          	jalr	-482(ra) # 80003a8e <brelse>
  bp = bread(dev, bno);
    80003c78:	85a6                	mv	a1,s1
    80003c7a:	855e                	mv	a0,s7
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	ce2080e7          	jalr	-798(ra) # 8000395e <bread>
    80003c84:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003c86:	40000613          	li	a2,1024
    80003c8a:	4581                	li	a1,0
    80003c8c:	05850513          	addi	a0,a0,88
    80003c90:	ffffd097          	auipc	ra,0xffffd
    80003c94:	196080e7          	jalr	406(ra) # 80000e26 <memset>
  log_write(bp);
    80003c98:	854a                	mv	a0,s2
    80003c9a:	00001097          	auipc	ra,0x1
    80003c9e:	078080e7          	jalr	120(ra) # 80004d12 <log_write>
  brelse(bp);
    80003ca2:	854a                	mv	a0,s2
    80003ca4:	00000097          	auipc	ra,0x0
    80003ca8:	dea080e7          	jalr	-534(ra) # 80003a8e <brelse>
}
    80003cac:	8526                	mv	a0,s1
    80003cae:	60e6                	ld	ra,88(sp)
    80003cb0:	6446                	ld	s0,80(sp)
    80003cb2:	64a6                	ld	s1,72(sp)
    80003cb4:	6906                	ld	s2,64(sp)
    80003cb6:	79e2                	ld	s3,56(sp)
    80003cb8:	7a42                	ld	s4,48(sp)
    80003cba:	7aa2                	ld	s5,40(sp)
    80003cbc:	7b02                	ld	s6,32(sp)
    80003cbe:	6be2                	ld	s7,24(sp)
    80003cc0:	6c42                	ld	s8,16(sp)
    80003cc2:	6ca2                	ld	s9,8(sp)
    80003cc4:	6125                	addi	sp,sp,96
    80003cc6:	8082                	ret
    brelse(bp);
    80003cc8:	854a                	mv	a0,s2
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	dc4080e7          	jalr	-572(ra) # 80003a8e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003cd2:	015c87bb          	addw	a5,s9,s5
    80003cd6:	00078a9b          	sext.w	s5,a5
    80003cda:	004b2703          	lw	a4,4(s6)
    80003cde:	06eaf363          	bgeu	s5,a4,80003d44 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003ce2:	41fad79b          	sraiw	a5,s5,0x1f
    80003ce6:	0137d79b          	srliw	a5,a5,0x13
    80003cea:	015787bb          	addw	a5,a5,s5
    80003cee:	40d7d79b          	sraiw	a5,a5,0xd
    80003cf2:	01cb2583          	lw	a1,28(s6)
    80003cf6:	9dbd                	addw	a1,a1,a5
    80003cf8:	855e                	mv	a0,s7
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	c64080e7          	jalr	-924(ra) # 8000395e <bread>
    80003d02:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d04:	004b2503          	lw	a0,4(s6)
    80003d08:	000a849b          	sext.w	s1,s5
    80003d0c:	8662                	mv	a2,s8
    80003d0e:	faa4fde3          	bgeu	s1,a0,80003cc8 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003d12:	41f6579b          	sraiw	a5,a2,0x1f
    80003d16:	01d7d69b          	srliw	a3,a5,0x1d
    80003d1a:	00c6873b          	addw	a4,a3,a2
    80003d1e:	00777793          	andi	a5,a4,7
    80003d22:	9f95                	subw	a5,a5,a3
    80003d24:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003d28:	4037571b          	sraiw	a4,a4,0x3
    80003d2c:	00e906b3          	add	a3,s2,a4
    80003d30:	0586c683          	lbu	a3,88(a3)
    80003d34:	00d7f5b3          	and	a1,a5,a3
    80003d38:	d195                	beqz	a1,80003c5c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d3a:	2605                	addiw	a2,a2,1
    80003d3c:	2485                	addiw	s1,s1,1
    80003d3e:	fd4618e3          	bne	a2,s4,80003d0e <balloc+0xee>
    80003d42:	b759                	j	80003cc8 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003d44:	00005517          	auipc	a0,0x5
    80003d48:	ac450513          	addi	a0,a0,-1340 # 80008808 <syscalls+0x130>
    80003d4c:	ffffd097          	auipc	ra,0xffffd
    80003d50:	842080e7          	jalr	-1982(ra) # 8000058e <printf>
  return 0;
    80003d54:	4481                	li	s1,0
    80003d56:	bf99                	j	80003cac <balloc+0x8c>

0000000080003d58 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003d58:	7179                	addi	sp,sp,-48
    80003d5a:	f406                	sd	ra,40(sp)
    80003d5c:	f022                	sd	s0,32(sp)
    80003d5e:	ec26                	sd	s1,24(sp)
    80003d60:	e84a                	sd	s2,16(sp)
    80003d62:	e44e                	sd	s3,8(sp)
    80003d64:	e052                	sd	s4,0(sp)
    80003d66:	1800                	addi	s0,sp,48
    80003d68:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003d6a:	47ad                	li	a5,11
    80003d6c:	02b7e763          	bltu	a5,a1,80003d9a <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003d70:	02059493          	slli	s1,a1,0x20
    80003d74:	9081                	srli	s1,s1,0x20
    80003d76:	048a                	slli	s1,s1,0x2
    80003d78:	94aa                	add	s1,s1,a0
    80003d7a:	0504a903          	lw	s2,80(s1)
    80003d7e:	06091e63          	bnez	s2,80003dfa <bmap+0xa2>
      addr = balloc(ip->dev);
    80003d82:	4108                	lw	a0,0(a0)
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	e9c080e7          	jalr	-356(ra) # 80003c20 <balloc>
    80003d8c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003d90:	06090563          	beqz	s2,80003dfa <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003d94:	0524a823          	sw	s2,80(s1)
    80003d98:	a08d                	j	80003dfa <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003d9a:	ff45849b          	addiw	s1,a1,-12
    80003d9e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003da2:	0ff00793          	li	a5,255
    80003da6:	08e7e563          	bltu	a5,a4,80003e30 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003daa:	08052903          	lw	s2,128(a0)
    80003dae:	00091d63          	bnez	s2,80003dc8 <bmap+0x70>
      addr = balloc(ip->dev);
    80003db2:	4108                	lw	a0,0(a0)
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	e6c080e7          	jalr	-404(ra) # 80003c20 <balloc>
    80003dbc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003dc0:	02090d63          	beqz	s2,80003dfa <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003dc4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003dc8:	85ca                	mv	a1,s2
    80003dca:	0009a503          	lw	a0,0(s3)
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	b90080e7          	jalr	-1136(ra) # 8000395e <bread>
    80003dd6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003dd8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ddc:	02049593          	slli	a1,s1,0x20
    80003de0:	9181                	srli	a1,a1,0x20
    80003de2:	058a                	slli	a1,a1,0x2
    80003de4:	00b784b3          	add	s1,a5,a1
    80003de8:	0004a903          	lw	s2,0(s1)
    80003dec:	02090063          	beqz	s2,80003e0c <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003df0:	8552                	mv	a0,s4
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	c9c080e7          	jalr	-868(ra) # 80003a8e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003dfa:	854a                	mv	a0,s2
    80003dfc:	70a2                	ld	ra,40(sp)
    80003dfe:	7402                	ld	s0,32(sp)
    80003e00:	64e2                	ld	s1,24(sp)
    80003e02:	6942                	ld	s2,16(sp)
    80003e04:	69a2                	ld	s3,8(sp)
    80003e06:	6a02                	ld	s4,0(sp)
    80003e08:	6145                	addi	sp,sp,48
    80003e0a:	8082                	ret
      addr = balloc(ip->dev);
    80003e0c:	0009a503          	lw	a0,0(s3)
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	e10080e7          	jalr	-496(ra) # 80003c20 <balloc>
    80003e18:	0005091b          	sext.w	s2,a0
      if(addr){
    80003e1c:	fc090ae3          	beqz	s2,80003df0 <bmap+0x98>
        a[bn] = addr;
    80003e20:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003e24:	8552                	mv	a0,s4
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	eec080e7          	jalr	-276(ra) # 80004d12 <log_write>
    80003e2e:	b7c9                	j	80003df0 <bmap+0x98>
  panic("bmap: out of range");
    80003e30:	00005517          	auipc	a0,0x5
    80003e34:	9f050513          	addi	a0,a0,-1552 # 80008820 <syscalls+0x148>
    80003e38:	ffffc097          	auipc	ra,0xffffc
    80003e3c:	70c080e7          	jalr	1804(ra) # 80000544 <panic>

0000000080003e40 <iget>:
{
    80003e40:	7179                	addi	sp,sp,-48
    80003e42:	f406                	sd	ra,40(sp)
    80003e44:	f022                	sd	s0,32(sp)
    80003e46:	ec26                	sd	s1,24(sp)
    80003e48:	e84a                	sd	s2,16(sp)
    80003e4a:	e44e                	sd	s3,8(sp)
    80003e4c:	e052                	sd	s4,0(sp)
    80003e4e:	1800                	addi	s0,sp,48
    80003e50:	89aa                	mv	s3,a0
    80003e52:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003e54:	0023e517          	auipc	a0,0x23e
    80003e58:	18450513          	addi	a0,a0,388 # 80241fd8 <itable>
    80003e5c:	ffffd097          	auipc	ra,0xffffd
    80003e60:	ece080e7          	jalr	-306(ra) # 80000d2a <acquire>
  empty = 0;
    80003e64:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e66:	0023e497          	auipc	s1,0x23e
    80003e6a:	18a48493          	addi	s1,s1,394 # 80241ff0 <itable+0x18>
    80003e6e:	00240697          	auipc	a3,0x240
    80003e72:	c1268693          	addi	a3,a3,-1006 # 80243a80 <log>
    80003e76:	a039                	j	80003e84 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e78:	02090b63          	beqz	s2,80003eae <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e7c:	08848493          	addi	s1,s1,136
    80003e80:	02d48a63          	beq	s1,a3,80003eb4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003e84:	449c                	lw	a5,8(s1)
    80003e86:	fef059e3          	blez	a5,80003e78 <iget+0x38>
    80003e8a:	4098                	lw	a4,0(s1)
    80003e8c:	ff3716e3          	bne	a4,s3,80003e78 <iget+0x38>
    80003e90:	40d8                	lw	a4,4(s1)
    80003e92:	ff4713e3          	bne	a4,s4,80003e78 <iget+0x38>
      ip->ref++;
    80003e96:	2785                	addiw	a5,a5,1
    80003e98:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003e9a:	0023e517          	auipc	a0,0x23e
    80003e9e:	13e50513          	addi	a0,a0,318 # 80241fd8 <itable>
    80003ea2:	ffffd097          	auipc	ra,0xffffd
    80003ea6:	f3c080e7          	jalr	-196(ra) # 80000dde <release>
      return ip;
    80003eaa:	8926                	mv	s2,s1
    80003eac:	a03d                	j	80003eda <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003eae:	f7f9                	bnez	a5,80003e7c <iget+0x3c>
    80003eb0:	8926                	mv	s2,s1
    80003eb2:	b7e9                	j	80003e7c <iget+0x3c>
  if(empty == 0)
    80003eb4:	02090c63          	beqz	s2,80003eec <iget+0xac>
  ip->dev = dev;
    80003eb8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ebc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ec0:	4785                	li	a5,1
    80003ec2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ec6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003eca:	0023e517          	auipc	a0,0x23e
    80003ece:	10e50513          	addi	a0,a0,270 # 80241fd8 <itable>
    80003ed2:	ffffd097          	auipc	ra,0xffffd
    80003ed6:	f0c080e7          	jalr	-244(ra) # 80000dde <release>
}
    80003eda:	854a                	mv	a0,s2
    80003edc:	70a2                	ld	ra,40(sp)
    80003ede:	7402                	ld	s0,32(sp)
    80003ee0:	64e2                	ld	s1,24(sp)
    80003ee2:	6942                	ld	s2,16(sp)
    80003ee4:	69a2                	ld	s3,8(sp)
    80003ee6:	6a02                	ld	s4,0(sp)
    80003ee8:	6145                	addi	sp,sp,48
    80003eea:	8082                	ret
    panic("iget: no inodes");
    80003eec:	00005517          	auipc	a0,0x5
    80003ef0:	94c50513          	addi	a0,a0,-1716 # 80008838 <syscalls+0x160>
    80003ef4:	ffffc097          	auipc	ra,0xffffc
    80003ef8:	650080e7          	jalr	1616(ra) # 80000544 <panic>

0000000080003efc <fsinit>:
fsinit(int dev) {
    80003efc:	7179                	addi	sp,sp,-48
    80003efe:	f406                	sd	ra,40(sp)
    80003f00:	f022                	sd	s0,32(sp)
    80003f02:	ec26                	sd	s1,24(sp)
    80003f04:	e84a                	sd	s2,16(sp)
    80003f06:	e44e                	sd	s3,8(sp)
    80003f08:	1800                	addi	s0,sp,48
    80003f0a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003f0c:	4585                	li	a1,1
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	a50080e7          	jalr	-1456(ra) # 8000395e <bread>
    80003f16:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003f18:	0023e997          	auipc	s3,0x23e
    80003f1c:	0a098993          	addi	s3,s3,160 # 80241fb8 <sb>
    80003f20:	02000613          	li	a2,32
    80003f24:	05850593          	addi	a1,a0,88
    80003f28:	854e                	mv	a0,s3
    80003f2a:	ffffd097          	auipc	ra,0xffffd
    80003f2e:	f5c080e7          	jalr	-164(ra) # 80000e86 <memmove>
  brelse(bp);
    80003f32:	8526                	mv	a0,s1
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	b5a080e7          	jalr	-1190(ra) # 80003a8e <brelse>
  if(sb.magic != FSMAGIC)
    80003f3c:	0009a703          	lw	a4,0(s3)
    80003f40:	102037b7          	lui	a5,0x10203
    80003f44:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003f48:	02f71263          	bne	a4,a5,80003f6c <fsinit+0x70>
  initlog(dev, &sb);
    80003f4c:	0023e597          	auipc	a1,0x23e
    80003f50:	06c58593          	addi	a1,a1,108 # 80241fb8 <sb>
    80003f54:	854a                	mv	a0,s2
    80003f56:	00001097          	auipc	ra,0x1
    80003f5a:	b40080e7          	jalr	-1216(ra) # 80004a96 <initlog>
}
    80003f5e:	70a2                	ld	ra,40(sp)
    80003f60:	7402                	ld	s0,32(sp)
    80003f62:	64e2                	ld	s1,24(sp)
    80003f64:	6942                	ld	s2,16(sp)
    80003f66:	69a2                	ld	s3,8(sp)
    80003f68:	6145                	addi	sp,sp,48
    80003f6a:	8082                	ret
    panic("invalid file system");
    80003f6c:	00005517          	auipc	a0,0x5
    80003f70:	8dc50513          	addi	a0,a0,-1828 # 80008848 <syscalls+0x170>
    80003f74:	ffffc097          	auipc	ra,0xffffc
    80003f78:	5d0080e7          	jalr	1488(ra) # 80000544 <panic>

0000000080003f7c <iinit>:
{
    80003f7c:	7179                	addi	sp,sp,-48
    80003f7e:	f406                	sd	ra,40(sp)
    80003f80:	f022                	sd	s0,32(sp)
    80003f82:	ec26                	sd	s1,24(sp)
    80003f84:	e84a                	sd	s2,16(sp)
    80003f86:	e44e                	sd	s3,8(sp)
    80003f88:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003f8a:	00005597          	auipc	a1,0x5
    80003f8e:	8d658593          	addi	a1,a1,-1834 # 80008860 <syscalls+0x188>
    80003f92:	0023e517          	auipc	a0,0x23e
    80003f96:	04650513          	addi	a0,a0,70 # 80241fd8 <itable>
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	d00080e7          	jalr	-768(ra) # 80000c9a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003fa2:	0023e497          	auipc	s1,0x23e
    80003fa6:	05e48493          	addi	s1,s1,94 # 80242000 <itable+0x28>
    80003faa:	00240997          	auipc	s3,0x240
    80003fae:	ae698993          	addi	s3,s3,-1306 # 80243a90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003fb2:	00005917          	auipc	s2,0x5
    80003fb6:	8b690913          	addi	s2,s2,-1866 # 80008868 <syscalls+0x190>
    80003fba:	85ca                	mv	a1,s2
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	00001097          	auipc	ra,0x1
    80003fc2:	e3a080e7          	jalr	-454(ra) # 80004df8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003fc6:	08848493          	addi	s1,s1,136
    80003fca:	ff3498e3          	bne	s1,s3,80003fba <iinit+0x3e>
}
    80003fce:	70a2                	ld	ra,40(sp)
    80003fd0:	7402                	ld	s0,32(sp)
    80003fd2:	64e2                	ld	s1,24(sp)
    80003fd4:	6942                	ld	s2,16(sp)
    80003fd6:	69a2                	ld	s3,8(sp)
    80003fd8:	6145                	addi	sp,sp,48
    80003fda:	8082                	ret

0000000080003fdc <ialloc>:
{
    80003fdc:	715d                	addi	sp,sp,-80
    80003fde:	e486                	sd	ra,72(sp)
    80003fe0:	e0a2                	sd	s0,64(sp)
    80003fe2:	fc26                	sd	s1,56(sp)
    80003fe4:	f84a                	sd	s2,48(sp)
    80003fe6:	f44e                	sd	s3,40(sp)
    80003fe8:	f052                	sd	s4,32(sp)
    80003fea:	ec56                	sd	s5,24(sp)
    80003fec:	e85a                	sd	s6,16(sp)
    80003fee:	e45e                	sd	s7,8(sp)
    80003ff0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ff2:	0023e717          	auipc	a4,0x23e
    80003ff6:	fd272703          	lw	a4,-46(a4) # 80241fc4 <sb+0xc>
    80003ffa:	4785                	li	a5,1
    80003ffc:	04e7fa63          	bgeu	a5,a4,80004050 <ialloc+0x74>
    80004000:	8aaa                	mv	s5,a0
    80004002:	8bae                	mv	s7,a1
    80004004:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004006:	0023ea17          	auipc	s4,0x23e
    8000400a:	fb2a0a13          	addi	s4,s4,-78 # 80241fb8 <sb>
    8000400e:	00048b1b          	sext.w	s6,s1
    80004012:	0044d593          	srli	a1,s1,0x4
    80004016:	018a2783          	lw	a5,24(s4)
    8000401a:	9dbd                	addw	a1,a1,a5
    8000401c:	8556                	mv	a0,s5
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	940080e7          	jalr	-1728(ra) # 8000395e <bread>
    80004026:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004028:	05850993          	addi	s3,a0,88
    8000402c:	00f4f793          	andi	a5,s1,15
    80004030:	079a                	slli	a5,a5,0x6
    80004032:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004034:	00099783          	lh	a5,0(s3)
    80004038:	c3a1                	beqz	a5,80004078 <ialloc+0x9c>
    brelse(bp);
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	a54080e7          	jalr	-1452(ra) # 80003a8e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004042:	0485                	addi	s1,s1,1
    80004044:	00ca2703          	lw	a4,12(s4)
    80004048:	0004879b          	sext.w	a5,s1
    8000404c:	fce7e1e3          	bltu	a5,a4,8000400e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80004050:	00005517          	auipc	a0,0x5
    80004054:	82050513          	addi	a0,a0,-2016 # 80008870 <syscalls+0x198>
    80004058:	ffffc097          	auipc	ra,0xffffc
    8000405c:	536080e7          	jalr	1334(ra) # 8000058e <printf>
  return 0;
    80004060:	4501                	li	a0,0
}
    80004062:	60a6                	ld	ra,72(sp)
    80004064:	6406                	ld	s0,64(sp)
    80004066:	74e2                	ld	s1,56(sp)
    80004068:	7942                	ld	s2,48(sp)
    8000406a:	79a2                	ld	s3,40(sp)
    8000406c:	7a02                	ld	s4,32(sp)
    8000406e:	6ae2                	ld	s5,24(sp)
    80004070:	6b42                	ld	s6,16(sp)
    80004072:	6ba2                	ld	s7,8(sp)
    80004074:	6161                	addi	sp,sp,80
    80004076:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004078:	04000613          	li	a2,64
    8000407c:	4581                	li	a1,0
    8000407e:	854e                	mv	a0,s3
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	da6080e7          	jalr	-602(ra) # 80000e26 <memset>
      dip->type = type;
    80004088:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000408c:	854a                	mv	a0,s2
    8000408e:	00001097          	auipc	ra,0x1
    80004092:	c84080e7          	jalr	-892(ra) # 80004d12 <log_write>
      brelse(bp);
    80004096:	854a                	mv	a0,s2
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	9f6080e7          	jalr	-1546(ra) # 80003a8e <brelse>
      return iget(dev, inum);
    800040a0:	85da                	mv	a1,s6
    800040a2:	8556                	mv	a0,s5
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	d9c080e7          	jalr	-612(ra) # 80003e40 <iget>
    800040ac:	bf5d                	j	80004062 <ialloc+0x86>

00000000800040ae <iupdate>:
{
    800040ae:	1101                	addi	sp,sp,-32
    800040b0:	ec06                	sd	ra,24(sp)
    800040b2:	e822                	sd	s0,16(sp)
    800040b4:	e426                	sd	s1,8(sp)
    800040b6:	e04a                	sd	s2,0(sp)
    800040b8:	1000                	addi	s0,sp,32
    800040ba:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800040bc:	415c                	lw	a5,4(a0)
    800040be:	0047d79b          	srliw	a5,a5,0x4
    800040c2:	0023e597          	auipc	a1,0x23e
    800040c6:	f0e5a583          	lw	a1,-242(a1) # 80241fd0 <sb+0x18>
    800040ca:	9dbd                	addw	a1,a1,a5
    800040cc:	4108                	lw	a0,0(a0)
    800040ce:	00000097          	auipc	ra,0x0
    800040d2:	890080e7          	jalr	-1904(ra) # 8000395e <bread>
    800040d6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040d8:	05850793          	addi	a5,a0,88
    800040dc:	40c8                	lw	a0,4(s1)
    800040de:	893d                	andi	a0,a0,15
    800040e0:	051a                	slli	a0,a0,0x6
    800040e2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800040e4:	04449703          	lh	a4,68(s1)
    800040e8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800040ec:	04649703          	lh	a4,70(s1)
    800040f0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800040f4:	04849703          	lh	a4,72(s1)
    800040f8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800040fc:	04a49703          	lh	a4,74(s1)
    80004100:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004104:	44f8                	lw	a4,76(s1)
    80004106:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004108:	03400613          	li	a2,52
    8000410c:	05048593          	addi	a1,s1,80
    80004110:	0531                	addi	a0,a0,12
    80004112:	ffffd097          	auipc	ra,0xffffd
    80004116:	d74080e7          	jalr	-652(ra) # 80000e86 <memmove>
  log_write(bp);
    8000411a:	854a                	mv	a0,s2
    8000411c:	00001097          	auipc	ra,0x1
    80004120:	bf6080e7          	jalr	-1034(ra) # 80004d12 <log_write>
  brelse(bp);
    80004124:	854a                	mv	a0,s2
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	968080e7          	jalr	-1688(ra) # 80003a8e <brelse>
}
    8000412e:	60e2                	ld	ra,24(sp)
    80004130:	6442                	ld	s0,16(sp)
    80004132:	64a2                	ld	s1,8(sp)
    80004134:	6902                	ld	s2,0(sp)
    80004136:	6105                	addi	sp,sp,32
    80004138:	8082                	ret

000000008000413a <idup>:
{
    8000413a:	1101                	addi	sp,sp,-32
    8000413c:	ec06                	sd	ra,24(sp)
    8000413e:	e822                	sd	s0,16(sp)
    80004140:	e426                	sd	s1,8(sp)
    80004142:	1000                	addi	s0,sp,32
    80004144:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004146:	0023e517          	auipc	a0,0x23e
    8000414a:	e9250513          	addi	a0,a0,-366 # 80241fd8 <itable>
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	bdc080e7          	jalr	-1060(ra) # 80000d2a <acquire>
  ip->ref++;
    80004156:	449c                	lw	a5,8(s1)
    80004158:	2785                	addiw	a5,a5,1
    8000415a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000415c:	0023e517          	auipc	a0,0x23e
    80004160:	e7c50513          	addi	a0,a0,-388 # 80241fd8 <itable>
    80004164:	ffffd097          	auipc	ra,0xffffd
    80004168:	c7a080e7          	jalr	-902(ra) # 80000dde <release>
}
    8000416c:	8526                	mv	a0,s1
    8000416e:	60e2                	ld	ra,24(sp)
    80004170:	6442                	ld	s0,16(sp)
    80004172:	64a2                	ld	s1,8(sp)
    80004174:	6105                	addi	sp,sp,32
    80004176:	8082                	ret

0000000080004178 <ilock>:
{
    80004178:	1101                	addi	sp,sp,-32
    8000417a:	ec06                	sd	ra,24(sp)
    8000417c:	e822                	sd	s0,16(sp)
    8000417e:	e426                	sd	s1,8(sp)
    80004180:	e04a                	sd	s2,0(sp)
    80004182:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004184:	c115                	beqz	a0,800041a8 <ilock+0x30>
    80004186:	84aa                	mv	s1,a0
    80004188:	451c                	lw	a5,8(a0)
    8000418a:	00f05f63          	blez	a5,800041a8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000418e:	0541                	addi	a0,a0,16
    80004190:	00001097          	auipc	ra,0x1
    80004194:	ca2080e7          	jalr	-862(ra) # 80004e32 <acquiresleep>
  if(ip->valid == 0){
    80004198:	40bc                	lw	a5,64(s1)
    8000419a:	cf99                	beqz	a5,800041b8 <ilock+0x40>
}
    8000419c:	60e2                	ld	ra,24(sp)
    8000419e:	6442                	ld	s0,16(sp)
    800041a0:	64a2                	ld	s1,8(sp)
    800041a2:	6902                	ld	s2,0(sp)
    800041a4:	6105                	addi	sp,sp,32
    800041a6:	8082                	ret
    panic("ilock");
    800041a8:	00004517          	auipc	a0,0x4
    800041ac:	6e050513          	addi	a0,a0,1760 # 80008888 <syscalls+0x1b0>
    800041b0:	ffffc097          	auipc	ra,0xffffc
    800041b4:	394080e7          	jalr	916(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041b8:	40dc                	lw	a5,4(s1)
    800041ba:	0047d79b          	srliw	a5,a5,0x4
    800041be:	0023e597          	auipc	a1,0x23e
    800041c2:	e125a583          	lw	a1,-494(a1) # 80241fd0 <sb+0x18>
    800041c6:	9dbd                	addw	a1,a1,a5
    800041c8:	4088                	lw	a0,0(s1)
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	794080e7          	jalr	1940(ra) # 8000395e <bread>
    800041d2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800041d4:	05850593          	addi	a1,a0,88
    800041d8:	40dc                	lw	a5,4(s1)
    800041da:	8bbd                	andi	a5,a5,15
    800041dc:	079a                	slli	a5,a5,0x6
    800041de:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800041e0:	00059783          	lh	a5,0(a1)
    800041e4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800041e8:	00259783          	lh	a5,2(a1)
    800041ec:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800041f0:	00459783          	lh	a5,4(a1)
    800041f4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800041f8:	00659783          	lh	a5,6(a1)
    800041fc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004200:	459c                	lw	a5,8(a1)
    80004202:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004204:	03400613          	li	a2,52
    80004208:	05b1                	addi	a1,a1,12
    8000420a:	05048513          	addi	a0,s1,80
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	c78080e7          	jalr	-904(ra) # 80000e86 <memmove>
    brelse(bp);
    80004216:	854a                	mv	a0,s2
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	876080e7          	jalr	-1930(ra) # 80003a8e <brelse>
    ip->valid = 1;
    80004220:	4785                	li	a5,1
    80004222:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004224:	04449783          	lh	a5,68(s1)
    80004228:	fbb5                	bnez	a5,8000419c <ilock+0x24>
      panic("ilock: no type");
    8000422a:	00004517          	auipc	a0,0x4
    8000422e:	66650513          	addi	a0,a0,1638 # 80008890 <syscalls+0x1b8>
    80004232:	ffffc097          	auipc	ra,0xffffc
    80004236:	312080e7          	jalr	786(ra) # 80000544 <panic>

000000008000423a <iunlock>:
{
    8000423a:	1101                	addi	sp,sp,-32
    8000423c:	ec06                	sd	ra,24(sp)
    8000423e:	e822                	sd	s0,16(sp)
    80004240:	e426                	sd	s1,8(sp)
    80004242:	e04a                	sd	s2,0(sp)
    80004244:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004246:	c905                	beqz	a0,80004276 <iunlock+0x3c>
    80004248:	84aa                	mv	s1,a0
    8000424a:	01050913          	addi	s2,a0,16
    8000424e:	854a                	mv	a0,s2
    80004250:	00001097          	auipc	ra,0x1
    80004254:	c7c080e7          	jalr	-900(ra) # 80004ecc <holdingsleep>
    80004258:	cd19                	beqz	a0,80004276 <iunlock+0x3c>
    8000425a:	449c                	lw	a5,8(s1)
    8000425c:	00f05d63          	blez	a5,80004276 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004260:	854a                	mv	a0,s2
    80004262:	00001097          	auipc	ra,0x1
    80004266:	c26080e7          	jalr	-986(ra) # 80004e88 <releasesleep>
}
    8000426a:	60e2                	ld	ra,24(sp)
    8000426c:	6442                	ld	s0,16(sp)
    8000426e:	64a2                	ld	s1,8(sp)
    80004270:	6902                	ld	s2,0(sp)
    80004272:	6105                	addi	sp,sp,32
    80004274:	8082                	ret
    panic("iunlock");
    80004276:	00004517          	auipc	a0,0x4
    8000427a:	62a50513          	addi	a0,a0,1578 # 800088a0 <syscalls+0x1c8>
    8000427e:	ffffc097          	auipc	ra,0xffffc
    80004282:	2c6080e7          	jalr	710(ra) # 80000544 <panic>

0000000080004286 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004286:	7179                	addi	sp,sp,-48
    80004288:	f406                	sd	ra,40(sp)
    8000428a:	f022                	sd	s0,32(sp)
    8000428c:	ec26                	sd	s1,24(sp)
    8000428e:	e84a                	sd	s2,16(sp)
    80004290:	e44e                	sd	s3,8(sp)
    80004292:	e052                	sd	s4,0(sp)
    80004294:	1800                	addi	s0,sp,48
    80004296:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004298:	05050493          	addi	s1,a0,80
    8000429c:	08050913          	addi	s2,a0,128
    800042a0:	a021                	j	800042a8 <itrunc+0x22>
    800042a2:	0491                	addi	s1,s1,4
    800042a4:	01248d63          	beq	s1,s2,800042be <itrunc+0x38>
    if(ip->addrs[i]){
    800042a8:	408c                	lw	a1,0(s1)
    800042aa:	dde5                	beqz	a1,800042a2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800042ac:	0009a503          	lw	a0,0(s3)
    800042b0:	00000097          	auipc	ra,0x0
    800042b4:	8f4080e7          	jalr	-1804(ra) # 80003ba4 <bfree>
      ip->addrs[i] = 0;
    800042b8:	0004a023          	sw	zero,0(s1)
    800042bc:	b7dd                	j	800042a2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800042be:	0809a583          	lw	a1,128(s3)
    800042c2:	e185                	bnez	a1,800042e2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800042c4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800042c8:	854e                	mv	a0,s3
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	de4080e7          	jalr	-540(ra) # 800040ae <iupdate>
}
    800042d2:	70a2                	ld	ra,40(sp)
    800042d4:	7402                	ld	s0,32(sp)
    800042d6:	64e2                	ld	s1,24(sp)
    800042d8:	6942                	ld	s2,16(sp)
    800042da:	69a2                	ld	s3,8(sp)
    800042dc:	6a02                	ld	s4,0(sp)
    800042de:	6145                	addi	sp,sp,48
    800042e0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800042e2:	0009a503          	lw	a0,0(s3)
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	678080e7          	jalr	1656(ra) # 8000395e <bread>
    800042ee:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800042f0:	05850493          	addi	s1,a0,88
    800042f4:	45850913          	addi	s2,a0,1112
    800042f8:	a811                	j	8000430c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800042fa:	0009a503          	lw	a0,0(s3)
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	8a6080e7          	jalr	-1882(ra) # 80003ba4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004306:	0491                	addi	s1,s1,4
    80004308:	01248563          	beq	s1,s2,80004312 <itrunc+0x8c>
      if(a[j])
    8000430c:	408c                	lw	a1,0(s1)
    8000430e:	dde5                	beqz	a1,80004306 <itrunc+0x80>
    80004310:	b7ed                	j	800042fa <itrunc+0x74>
    brelse(bp);
    80004312:	8552                	mv	a0,s4
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	77a080e7          	jalr	1914(ra) # 80003a8e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000431c:	0809a583          	lw	a1,128(s3)
    80004320:	0009a503          	lw	a0,0(s3)
    80004324:	00000097          	auipc	ra,0x0
    80004328:	880080e7          	jalr	-1920(ra) # 80003ba4 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000432c:	0809a023          	sw	zero,128(s3)
    80004330:	bf51                	j	800042c4 <itrunc+0x3e>

0000000080004332 <iput>:
{
    80004332:	1101                	addi	sp,sp,-32
    80004334:	ec06                	sd	ra,24(sp)
    80004336:	e822                	sd	s0,16(sp)
    80004338:	e426                	sd	s1,8(sp)
    8000433a:	e04a                	sd	s2,0(sp)
    8000433c:	1000                	addi	s0,sp,32
    8000433e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004340:	0023e517          	auipc	a0,0x23e
    80004344:	c9850513          	addi	a0,a0,-872 # 80241fd8 <itable>
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	9e2080e7          	jalr	-1566(ra) # 80000d2a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004350:	4498                	lw	a4,8(s1)
    80004352:	4785                	li	a5,1
    80004354:	02f70363          	beq	a4,a5,8000437a <iput+0x48>
  ip->ref--;
    80004358:	449c                	lw	a5,8(s1)
    8000435a:	37fd                	addiw	a5,a5,-1
    8000435c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000435e:	0023e517          	auipc	a0,0x23e
    80004362:	c7a50513          	addi	a0,a0,-902 # 80241fd8 <itable>
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	a78080e7          	jalr	-1416(ra) # 80000dde <release>
}
    8000436e:	60e2                	ld	ra,24(sp)
    80004370:	6442                	ld	s0,16(sp)
    80004372:	64a2                	ld	s1,8(sp)
    80004374:	6902                	ld	s2,0(sp)
    80004376:	6105                	addi	sp,sp,32
    80004378:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000437a:	40bc                	lw	a5,64(s1)
    8000437c:	dff1                	beqz	a5,80004358 <iput+0x26>
    8000437e:	04a49783          	lh	a5,74(s1)
    80004382:	fbf9                	bnez	a5,80004358 <iput+0x26>
    acquiresleep(&ip->lock);
    80004384:	01048913          	addi	s2,s1,16
    80004388:	854a                	mv	a0,s2
    8000438a:	00001097          	auipc	ra,0x1
    8000438e:	aa8080e7          	jalr	-1368(ra) # 80004e32 <acquiresleep>
    release(&itable.lock);
    80004392:	0023e517          	auipc	a0,0x23e
    80004396:	c4650513          	addi	a0,a0,-954 # 80241fd8 <itable>
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	a44080e7          	jalr	-1468(ra) # 80000dde <release>
    itrunc(ip);
    800043a2:	8526                	mv	a0,s1
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	ee2080e7          	jalr	-286(ra) # 80004286 <itrunc>
    ip->type = 0;
    800043ac:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800043b0:	8526                	mv	a0,s1
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	cfc080e7          	jalr	-772(ra) # 800040ae <iupdate>
    ip->valid = 0;
    800043ba:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800043be:	854a                	mv	a0,s2
    800043c0:	00001097          	auipc	ra,0x1
    800043c4:	ac8080e7          	jalr	-1336(ra) # 80004e88 <releasesleep>
    acquire(&itable.lock);
    800043c8:	0023e517          	auipc	a0,0x23e
    800043cc:	c1050513          	addi	a0,a0,-1008 # 80241fd8 <itable>
    800043d0:	ffffd097          	auipc	ra,0xffffd
    800043d4:	95a080e7          	jalr	-1702(ra) # 80000d2a <acquire>
    800043d8:	b741                	j	80004358 <iput+0x26>

00000000800043da <iunlockput>:
{
    800043da:	1101                	addi	sp,sp,-32
    800043dc:	ec06                	sd	ra,24(sp)
    800043de:	e822                	sd	s0,16(sp)
    800043e0:	e426                	sd	s1,8(sp)
    800043e2:	1000                	addi	s0,sp,32
    800043e4:	84aa                	mv	s1,a0
  iunlock(ip);
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	e54080e7          	jalr	-428(ra) # 8000423a <iunlock>
  iput(ip);
    800043ee:	8526                	mv	a0,s1
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	f42080e7          	jalr	-190(ra) # 80004332 <iput>
}
    800043f8:	60e2                	ld	ra,24(sp)
    800043fa:	6442                	ld	s0,16(sp)
    800043fc:	64a2                	ld	s1,8(sp)
    800043fe:	6105                	addi	sp,sp,32
    80004400:	8082                	ret

0000000080004402 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004402:	1141                	addi	sp,sp,-16
    80004404:	e422                	sd	s0,8(sp)
    80004406:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004408:	411c                	lw	a5,0(a0)
    8000440a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000440c:	415c                	lw	a5,4(a0)
    8000440e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004410:	04451783          	lh	a5,68(a0)
    80004414:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004418:	04a51783          	lh	a5,74(a0)
    8000441c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004420:	04c56783          	lwu	a5,76(a0)
    80004424:	e99c                	sd	a5,16(a1)
}
    80004426:	6422                	ld	s0,8(sp)
    80004428:	0141                	addi	sp,sp,16
    8000442a:	8082                	ret

000000008000442c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000442c:	457c                	lw	a5,76(a0)
    8000442e:	0ed7e963          	bltu	a5,a3,80004520 <readi+0xf4>
{
    80004432:	7159                	addi	sp,sp,-112
    80004434:	f486                	sd	ra,104(sp)
    80004436:	f0a2                	sd	s0,96(sp)
    80004438:	eca6                	sd	s1,88(sp)
    8000443a:	e8ca                	sd	s2,80(sp)
    8000443c:	e4ce                	sd	s3,72(sp)
    8000443e:	e0d2                	sd	s4,64(sp)
    80004440:	fc56                	sd	s5,56(sp)
    80004442:	f85a                	sd	s6,48(sp)
    80004444:	f45e                	sd	s7,40(sp)
    80004446:	f062                	sd	s8,32(sp)
    80004448:	ec66                	sd	s9,24(sp)
    8000444a:	e86a                	sd	s10,16(sp)
    8000444c:	e46e                	sd	s11,8(sp)
    8000444e:	1880                	addi	s0,sp,112
    80004450:	8b2a                	mv	s6,a0
    80004452:	8bae                	mv	s7,a1
    80004454:	8a32                	mv	s4,a2
    80004456:	84b6                	mv	s1,a3
    80004458:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000445a:	9f35                	addw	a4,a4,a3
    return 0;
    8000445c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000445e:	0ad76063          	bltu	a4,a3,800044fe <readi+0xd2>
  if(off + n > ip->size)
    80004462:	00e7f463          	bgeu	a5,a4,8000446a <readi+0x3e>
    n = ip->size - off;
    80004466:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000446a:	0a0a8963          	beqz	s5,8000451c <readi+0xf0>
    8000446e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004470:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004474:	5c7d                	li	s8,-1
    80004476:	a82d                	j	800044b0 <readi+0x84>
    80004478:	020d1d93          	slli	s11,s10,0x20
    8000447c:	020ddd93          	srli	s11,s11,0x20
    80004480:	05890613          	addi	a2,s2,88
    80004484:	86ee                	mv	a3,s11
    80004486:	963a                	add	a2,a2,a4
    80004488:	85d2                	mv	a1,s4
    8000448a:	855e                	mv	a0,s7
    8000448c:	ffffe097          	auipc	ra,0xffffe
    80004490:	76e080e7          	jalr	1902(ra) # 80002bfa <either_copyout>
    80004494:	05850d63          	beq	a0,s8,800044ee <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004498:	854a                	mv	a0,s2
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	5f4080e7          	jalr	1524(ra) # 80003a8e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800044a2:	013d09bb          	addw	s3,s10,s3
    800044a6:	009d04bb          	addw	s1,s10,s1
    800044aa:	9a6e                	add	s4,s4,s11
    800044ac:	0559f763          	bgeu	s3,s5,800044fa <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800044b0:	00a4d59b          	srliw	a1,s1,0xa
    800044b4:	855a                	mv	a0,s6
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	8a2080e7          	jalr	-1886(ra) # 80003d58 <bmap>
    800044be:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800044c2:	cd85                	beqz	a1,800044fa <readi+0xce>
    bp = bread(ip->dev, addr);
    800044c4:	000b2503          	lw	a0,0(s6)
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	496080e7          	jalr	1174(ra) # 8000395e <bread>
    800044d0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044d2:	3ff4f713          	andi	a4,s1,1023
    800044d6:	40ec87bb          	subw	a5,s9,a4
    800044da:	413a86bb          	subw	a3,s5,s3
    800044de:	8d3e                	mv	s10,a5
    800044e0:	2781                	sext.w	a5,a5
    800044e2:	0006861b          	sext.w	a2,a3
    800044e6:	f8f679e3          	bgeu	a2,a5,80004478 <readi+0x4c>
    800044ea:	8d36                	mv	s10,a3
    800044ec:	b771                	j	80004478 <readi+0x4c>
      brelse(bp);
    800044ee:	854a                	mv	a0,s2
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	59e080e7          	jalr	1438(ra) # 80003a8e <brelse>
      tot = -1;
    800044f8:	59fd                	li	s3,-1
  }
  return tot;
    800044fa:	0009851b          	sext.w	a0,s3
}
    800044fe:	70a6                	ld	ra,104(sp)
    80004500:	7406                	ld	s0,96(sp)
    80004502:	64e6                	ld	s1,88(sp)
    80004504:	6946                	ld	s2,80(sp)
    80004506:	69a6                	ld	s3,72(sp)
    80004508:	6a06                	ld	s4,64(sp)
    8000450a:	7ae2                	ld	s5,56(sp)
    8000450c:	7b42                	ld	s6,48(sp)
    8000450e:	7ba2                	ld	s7,40(sp)
    80004510:	7c02                	ld	s8,32(sp)
    80004512:	6ce2                	ld	s9,24(sp)
    80004514:	6d42                	ld	s10,16(sp)
    80004516:	6da2                	ld	s11,8(sp)
    80004518:	6165                	addi	sp,sp,112
    8000451a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000451c:	89d6                	mv	s3,s5
    8000451e:	bff1                	j	800044fa <readi+0xce>
    return 0;
    80004520:	4501                	li	a0,0
}
    80004522:	8082                	ret

0000000080004524 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004524:	457c                	lw	a5,76(a0)
    80004526:	10d7e863          	bltu	a5,a3,80004636 <writei+0x112>
{
    8000452a:	7159                	addi	sp,sp,-112
    8000452c:	f486                	sd	ra,104(sp)
    8000452e:	f0a2                	sd	s0,96(sp)
    80004530:	eca6                	sd	s1,88(sp)
    80004532:	e8ca                	sd	s2,80(sp)
    80004534:	e4ce                	sd	s3,72(sp)
    80004536:	e0d2                	sd	s4,64(sp)
    80004538:	fc56                	sd	s5,56(sp)
    8000453a:	f85a                	sd	s6,48(sp)
    8000453c:	f45e                	sd	s7,40(sp)
    8000453e:	f062                	sd	s8,32(sp)
    80004540:	ec66                	sd	s9,24(sp)
    80004542:	e86a                	sd	s10,16(sp)
    80004544:	e46e                	sd	s11,8(sp)
    80004546:	1880                	addi	s0,sp,112
    80004548:	8aaa                	mv	s5,a0
    8000454a:	8bae                	mv	s7,a1
    8000454c:	8a32                	mv	s4,a2
    8000454e:	8936                	mv	s2,a3
    80004550:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004552:	00e687bb          	addw	a5,a3,a4
    80004556:	0ed7e263          	bltu	a5,a3,8000463a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000455a:	00043737          	lui	a4,0x43
    8000455e:	0ef76063          	bltu	a4,a5,8000463e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004562:	0c0b0863          	beqz	s6,80004632 <writei+0x10e>
    80004566:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004568:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000456c:	5c7d                	li	s8,-1
    8000456e:	a091                	j	800045b2 <writei+0x8e>
    80004570:	020d1d93          	slli	s11,s10,0x20
    80004574:	020ddd93          	srli	s11,s11,0x20
    80004578:	05848513          	addi	a0,s1,88
    8000457c:	86ee                	mv	a3,s11
    8000457e:	8652                	mv	a2,s4
    80004580:	85de                	mv	a1,s7
    80004582:	953a                	add	a0,a0,a4
    80004584:	ffffe097          	auipc	ra,0xffffe
    80004588:	6cc080e7          	jalr	1740(ra) # 80002c50 <either_copyin>
    8000458c:	07850263          	beq	a0,s8,800045f0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004590:	8526                	mv	a0,s1
    80004592:	00000097          	auipc	ra,0x0
    80004596:	780080e7          	jalr	1920(ra) # 80004d12 <log_write>
    brelse(bp);
    8000459a:	8526                	mv	a0,s1
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	4f2080e7          	jalr	1266(ra) # 80003a8e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045a4:	013d09bb          	addw	s3,s10,s3
    800045a8:	012d093b          	addw	s2,s10,s2
    800045ac:	9a6e                	add	s4,s4,s11
    800045ae:	0569f663          	bgeu	s3,s6,800045fa <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800045b2:	00a9559b          	srliw	a1,s2,0xa
    800045b6:	8556                	mv	a0,s5
    800045b8:	fffff097          	auipc	ra,0xfffff
    800045bc:	7a0080e7          	jalr	1952(ra) # 80003d58 <bmap>
    800045c0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800045c4:	c99d                	beqz	a1,800045fa <writei+0xd6>
    bp = bread(ip->dev, addr);
    800045c6:	000aa503          	lw	a0,0(s5)
    800045ca:	fffff097          	auipc	ra,0xfffff
    800045ce:	394080e7          	jalr	916(ra) # 8000395e <bread>
    800045d2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800045d4:	3ff97713          	andi	a4,s2,1023
    800045d8:	40ec87bb          	subw	a5,s9,a4
    800045dc:	413b06bb          	subw	a3,s6,s3
    800045e0:	8d3e                	mv	s10,a5
    800045e2:	2781                	sext.w	a5,a5
    800045e4:	0006861b          	sext.w	a2,a3
    800045e8:	f8f674e3          	bgeu	a2,a5,80004570 <writei+0x4c>
    800045ec:	8d36                	mv	s10,a3
    800045ee:	b749                	j	80004570 <writei+0x4c>
      brelse(bp);
    800045f0:	8526                	mv	a0,s1
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	49c080e7          	jalr	1180(ra) # 80003a8e <brelse>
  }

  if(off > ip->size)
    800045fa:	04caa783          	lw	a5,76(s5)
    800045fe:	0127f463          	bgeu	a5,s2,80004606 <writei+0xe2>
    ip->size = off;
    80004602:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004606:	8556                	mv	a0,s5
    80004608:	00000097          	auipc	ra,0x0
    8000460c:	aa6080e7          	jalr	-1370(ra) # 800040ae <iupdate>

  return tot;
    80004610:	0009851b          	sext.w	a0,s3
}
    80004614:	70a6                	ld	ra,104(sp)
    80004616:	7406                	ld	s0,96(sp)
    80004618:	64e6                	ld	s1,88(sp)
    8000461a:	6946                	ld	s2,80(sp)
    8000461c:	69a6                	ld	s3,72(sp)
    8000461e:	6a06                	ld	s4,64(sp)
    80004620:	7ae2                	ld	s5,56(sp)
    80004622:	7b42                	ld	s6,48(sp)
    80004624:	7ba2                	ld	s7,40(sp)
    80004626:	7c02                	ld	s8,32(sp)
    80004628:	6ce2                	ld	s9,24(sp)
    8000462a:	6d42                	ld	s10,16(sp)
    8000462c:	6da2                	ld	s11,8(sp)
    8000462e:	6165                	addi	sp,sp,112
    80004630:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004632:	89da                	mv	s3,s6
    80004634:	bfc9                	j	80004606 <writei+0xe2>
    return -1;
    80004636:	557d                	li	a0,-1
}
    80004638:	8082                	ret
    return -1;
    8000463a:	557d                	li	a0,-1
    8000463c:	bfe1                	j	80004614 <writei+0xf0>
    return -1;
    8000463e:	557d                	li	a0,-1
    80004640:	bfd1                	j	80004614 <writei+0xf0>

0000000080004642 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004642:	1141                	addi	sp,sp,-16
    80004644:	e406                	sd	ra,8(sp)
    80004646:	e022                	sd	s0,0(sp)
    80004648:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000464a:	4639                	li	a2,14
    8000464c:	ffffd097          	auipc	ra,0xffffd
    80004650:	8b2080e7          	jalr	-1870(ra) # 80000efe <strncmp>
}
    80004654:	60a2                	ld	ra,8(sp)
    80004656:	6402                	ld	s0,0(sp)
    80004658:	0141                	addi	sp,sp,16
    8000465a:	8082                	ret

000000008000465c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000465c:	7139                	addi	sp,sp,-64
    8000465e:	fc06                	sd	ra,56(sp)
    80004660:	f822                	sd	s0,48(sp)
    80004662:	f426                	sd	s1,40(sp)
    80004664:	f04a                	sd	s2,32(sp)
    80004666:	ec4e                	sd	s3,24(sp)
    80004668:	e852                	sd	s4,16(sp)
    8000466a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000466c:	04451703          	lh	a4,68(a0)
    80004670:	4785                	li	a5,1
    80004672:	00f71a63          	bne	a4,a5,80004686 <dirlookup+0x2a>
    80004676:	892a                	mv	s2,a0
    80004678:	89ae                	mv	s3,a1
    8000467a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000467c:	457c                	lw	a5,76(a0)
    8000467e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004680:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004682:	e79d                	bnez	a5,800046b0 <dirlookup+0x54>
    80004684:	a8a5                	j	800046fc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004686:	00004517          	auipc	a0,0x4
    8000468a:	22250513          	addi	a0,a0,546 # 800088a8 <syscalls+0x1d0>
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	eb6080e7          	jalr	-330(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004696:	00004517          	auipc	a0,0x4
    8000469a:	22a50513          	addi	a0,a0,554 # 800088c0 <syscalls+0x1e8>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	ea6080e7          	jalr	-346(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046a6:	24c1                	addiw	s1,s1,16
    800046a8:	04c92783          	lw	a5,76(s2)
    800046ac:	04f4f763          	bgeu	s1,a5,800046fa <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046b0:	4741                	li	a4,16
    800046b2:	86a6                	mv	a3,s1
    800046b4:	fc040613          	addi	a2,s0,-64
    800046b8:	4581                	li	a1,0
    800046ba:	854a                	mv	a0,s2
    800046bc:	00000097          	auipc	ra,0x0
    800046c0:	d70080e7          	jalr	-656(ra) # 8000442c <readi>
    800046c4:	47c1                	li	a5,16
    800046c6:	fcf518e3          	bne	a0,a5,80004696 <dirlookup+0x3a>
    if(de.inum == 0)
    800046ca:	fc045783          	lhu	a5,-64(s0)
    800046ce:	dfe1                	beqz	a5,800046a6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800046d0:	fc240593          	addi	a1,s0,-62
    800046d4:	854e                	mv	a0,s3
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	f6c080e7          	jalr	-148(ra) # 80004642 <namecmp>
    800046de:	f561                	bnez	a0,800046a6 <dirlookup+0x4a>
      if(poff)
    800046e0:	000a0463          	beqz	s4,800046e8 <dirlookup+0x8c>
        *poff = off;
    800046e4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800046e8:	fc045583          	lhu	a1,-64(s0)
    800046ec:	00092503          	lw	a0,0(s2)
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	750080e7          	jalr	1872(ra) # 80003e40 <iget>
    800046f8:	a011                	j	800046fc <dirlookup+0xa0>
  return 0;
    800046fa:	4501                	li	a0,0
}
    800046fc:	70e2                	ld	ra,56(sp)
    800046fe:	7442                	ld	s0,48(sp)
    80004700:	74a2                	ld	s1,40(sp)
    80004702:	7902                	ld	s2,32(sp)
    80004704:	69e2                	ld	s3,24(sp)
    80004706:	6a42                	ld	s4,16(sp)
    80004708:	6121                	addi	sp,sp,64
    8000470a:	8082                	ret

000000008000470c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000470c:	711d                	addi	sp,sp,-96
    8000470e:	ec86                	sd	ra,88(sp)
    80004710:	e8a2                	sd	s0,80(sp)
    80004712:	e4a6                	sd	s1,72(sp)
    80004714:	e0ca                	sd	s2,64(sp)
    80004716:	fc4e                	sd	s3,56(sp)
    80004718:	f852                	sd	s4,48(sp)
    8000471a:	f456                	sd	s5,40(sp)
    8000471c:	f05a                	sd	s6,32(sp)
    8000471e:	ec5e                	sd	s7,24(sp)
    80004720:	e862                	sd	s8,16(sp)
    80004722:	e466                	sd	s9,8(sp)
    80004724:	1080                	addi	s0,sp,96
    80004726:	84aa                	mv	s1,a0
    80004728:	8b2e                	mv	s6,a1
    8000472a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000472c:	00054703          	lbu	a4,0(a0)
    80004730:	02f00793          	li	a5,47
    80004734:	02f70363          	beq	a4,a5,8000475a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004738:	ffffd097          	auipc	ra,0xffffd
    8000473c:	626080e7          	jalr	1574(ra) # 80001d5e <myproc>
    80004740:	15053503          	ld	a0,336(a0)
    80004744:	00000097          	auipc	ra,0x0
    80004748:	9f6080e7          	jalr	-1546(ra) # 8000413a <idup>
    8000474c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000474e:	02f00913          	li	s2,47
  len = path - s;
    80004752:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004754:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004756:	4c05                	li	s8,1
    80004758:	a865                	j	80004810 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000475a:	4585                	li	a1,1
    8000475c:	4505                	li	a0,1
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	6e2080e7          	jalr	1762(ra) # 80003e40 <iget>
    80004766:	89aa                	mv	s3,a0
    80004768:	b7dd                	j	8000474e <namex+0x42>
      iunlockput(ip);
    8000476a:	854e                	mv	a0,s3
    8000476c:	00000097          	auipc	ra,0x0
    80004770:	c6e080e7          	jalr	-914(ra) # 800043da <iunlockput>
      return 0;
    80004774:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004776:	854e                	mv	a0,s3
    80004778:	60e6                	ld	ra,88(sp)
    8000477a:	6446                	ld	s0,80(sp)
    8000477c:	64a6                	ld	s1,72(sp)
    8000477e:	6906                	ld	s2,64(sp)
    80004780:	79e2                	ld	s3,56(sp)
    80004782:	7a42                	ld	s4,48(sp)
    80004784:	7aa2                	ld	s5,40(sp)
    80004786:	7b02                	ld	s6,32(sp)
    80004788:	6be2                	ld	s7,24(sp)
    8000478a:	6c42                	ld	s8,16(sp)
    8000478c:	6ca2                	ld	s9,8(sp)
    8000478e:	6125                	addi	sp,sp,96
    80004790:	8082                	ret
      iunlock(ip);
    80004792:	854e                	mv	a0,s3
    80004794:	00000097          	auipc	ra,0x0
    80004798:	aa6080e7          	jalr	-1370(ra) # 8000423a <iunlock>
      return ip;
    8000479c:	bfe9                	j	80004776 <namex+0x6a>
      iunlockput(ip);
    8000479e:	854e                	mv	a0,s3
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	c3a080e7          	jalr	-966(ra) # 800043da <iunlockput>
      return 0;
    800047a8:	89d2                	mv	s3,s4
    800047aa:	b7f1                	j	80004776 <namex+0x6a>
  len = path - s;
    800047ac:	40b48633          	sub	a2,s1,a1
    800047b0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800047b4:	094cd463          	bge	s9,s4,8000483c <namex+0x130>
    memmove(name, s, DIRSIZ);
    800047b8:	4639                	li	a2,14
    800047ba:	8556                	mv	a0,s5
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	6ca080e7          	jalr	1738(ra) # 80000e86 <memmove>
  while(*path == '/')
    800047c4:	0004c783          	lbu	a5,0(s1)
    800047c8:	01279763          	bne	a5,s2,800047d6 <namex+0xca>
    path++;
    800047cc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800047ce:	0004c783          	lbu	a5,0(s1)
    800047d2:	ff278de3          	beq	a5,s2,800047cc <namex+0xc0>
    ilock(ip);
    800047d6:	854e                	mv	a0,s3
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	9a0080e7          	jalr	-1632(ra) # 80004178 <ilock>
    if(ip->type != T_DIR){
    800047e0:	04499783          	lh	a5,68(s3)
    800047e4:	f98793e3          	bne	a5,s8,8000476a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800047e8:	000b0563          	beqz	s6,800047f2 <namex+0xe6>
    800047ec:	0004c783          	lbu	a5,0(s1)
    800047f0:	d3cd                	beqz	a5,80004792 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800047f2:	865e                	mv	a2,s7
    800047f4:	85d6                	mv	a1,s5
    800047f6:	854e                	mv	a0,s3
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	e64080e7          	jalr	-412(ra) # 8000465c <dirlookup>
    80004800:	8a2a                	mv	s4,a0
    80004802:	dd51                	beqz	a0,8000479e <namex+0x92>
    iunlockput(ip);
    80004804:	854e                	mv	a0,s3
    80004806:	00000097          	auipc	ra,0x0
    8000480a:	bd4080e7          	jalr	-1068(ra) # 800043da <iunlockput>
    ip = next;
    8000480e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004810:	0004c783          	lbu	a5,0(s1)
    80004814:	05279763          	bne	a5,s2,80004862 <namex+0x156>
    path++;
    80004818:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000481a:	0004c783          	lbu	a5,0(s1)
    8000481e:	ff278de3          	beq	a5,s2,80004818 <namex+0x10c>
  if(*path == 0)
    80004822:	c79d                	beqz	a5,80004850 <namex+0x144>
    path++;
    80004824:	85a6                	mv	a1,s1
  len = path - s;
    80004826:	8a5e                	mv	s4,s7
    80004828:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000482a:	01278963          	beq	a5,s2,8000483c <namex+0x130>
    8000482e:	dfbd                	beqz	a5,800047ac <namex+0xa0>
    path++;
    80004830:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004832:	0004c783          	lbu	a5,0(s1)
    80004836:	ff279ce3          	bne	a5,s2,8000482e <namex+0x122>
    8000483a:	bf8d                	j	800047ac <namex+0xa0>
    memmove(name, s, len);
    8000483c:	2601                	sext.w	a2,a2
    8000483e:	8556                	mv	a0,s5
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	646080e7          	jalr	1606(ra) # 80000e86 <memmove>
    name[len] = 0;
    80004848:	9a56                	add	s4,s4,s5
    8000484a:	000a0023          	sb	zero,0(s4)
    8000484e:	bf9d                	j	800047c4 <namex+0xb8>
  if(nameiparent){
    80004850:	f20b03e3          	beqz	s6,80004776 <namex+0x6a>
    iput(ip);
    80004854:	854e                	mv	a0,s3
    80004856:	00000097          	auipc	ra,0x0
    8000485a:	adc080e7          	jalr	-1316(ra) # 80004332 <iput>
    return 0;
    8000485e:	4981                	li	s3,0
    80004860:	bf19                	j	80004776 <namex+0x6a>
  if(*path == 0)
    80004862:	d7fd                	beqz	a5,80004850 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004864:	0004c783          	lbu	a5,0(s1)
    80004868:	85a6                	mv	a1,s1
    8000486a:	b7d1                	j	8000482e <namex+0x122>

000000008000486c <dirlink>:
{
    8000486c:	7139                	addi	sp,sp,-64
    8000486e:	fc06                	sd	ra,56(sp)
    80004870:	f822                	sd	s0,48(sp)
    80004872:	f426                	sd	s1,40(sp)
    80004874:	f04a                	sd	s2,32(sp)
    80004876:	ec4e                	sd	s3,24(sp)
    80004878:	e852                	sd	s4,16(sp)
    8000487a:	0080                	addi	s0,sp,64
    8000487c:	892a                	mv	s2,a0
    8000487e:	8a2e                	mv	s4,a1
    80004880:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004882:	4601                	li	a2,0
    80004884:	00000097          	auipc	ra,0x0
    80004888:	dd8080e7          	jalr	-552(ra) # 8000465c <dirlookup>
    8000488c:	e93d                	bnez	a0,80004902 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000488e:	04c92483          	lw	s1,76(s2)
    80004892:	c49d                	beqz	s1,800048c0 <dirlink+0x54>
    80004894:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004896:	4741                	li	a4,16
    80004898:	86a6                	mv	a3,s1
    8000489a:	fc040613          	addi	a2,s0,-64
    8000489e:	4581                	li	a1,0
    800048a0:	854a                	mv	a0,s2
    800048a2:	00000097          	auipc	ra,0x0
    800048a6:	b8a080e7          	jalr	-1142(ra) # 8000442c <readi>
    800048aa:	47c1                	li	a5,16
    800048ac:	06f51163          	bne	a0,a5,8000490e <dirlink+0xa2>
    if(de.inum == 0)
    800048b0:	fc045783          	lhu	a5,-64(s0)
    800048b4:	c791                	beqz	a5,800048c0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048b6:	24c1                	addiw	s1,s1,16
    800048b8:	04c92783          	lw	a5,76(s2)
    800048bc:	fcf4ede3          	bltu	s1,a5,80004896 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800048c0:	4639                	li	a2,14
    800048c2:	85d2                	mv	a1,s4
    800048c4:	fc240513          	addi	a0,s0,-62
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	672080e7          	jalr	1650(ra) # 80000f3a <strncpy>
  de.inum = inum;
    800048d0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048d4:	4741                	li	a4,16
    800048d6:	86a6                	mv	a3,s1
    800048d8:	fc040613          	addi	a2,s0,-64
    800048dc:	4581                	li	a1,0
    800048de:	854a                	mv	a0,s2
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	c44080e7          	jalr	-956(ra) # 80004524 <writei>
    800048e8:	1541                	addi	a0,a0,-16
    800048ea:	00a03533          	snez	a0,a0
    800048ee:	40a00533          	neg	a0,a0
}
    800048f2:	70e2                	ld	ra,56(sp)
    800048f4:	7442                	ld	s0,48(sp)
    800048f6:	74a2                	ld	s1,40(sp)
    800048f8:	7902                	ld	s2,32(sp)
    800048fa:	69e2                	ld	s3,24(sp)
    800048fc:	6a42                	ld	s4,16(sp)
    800048fe:	6121                	addi	sp,sp,64
    80004900:	8082                	ret
    iput(ip);
    80004902:	00000097          	auipc	ra,0x0
    80004906:	a30080e7          	jalr	-1488(ra) # 80004332 <iput>
    return -1;
    8000490a:	557d                	li	a0,-1
    8000490c:	b7dd                	j	800048f2 <dirlink+0x86>
      panic("dirlink read");
    8000490e:	00004517          	auipc	a0,0x4
    80004912:	fc250513          	addi	a0,a0,-62 # 800088d0 <syscalls+0x1f8>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	c2e080e7          	jalr	-978(ra) # 80000544 <panic>

000000008000491e <namei>:

struct inode*
namei(char *path)
{
    8000491e:	1101                	addi	sp,sp,-32
    80004920:	ec06                	sd	ra,24(sp)
    80004922:	e822                	sd	s0,16(sp)
    80004924:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004926:	fe040613          	addi	a2,s0,-32
    8000492a:	4581                	li	a1,0
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	de0080e7          	jalr	-544(ra) # 8000470c <namex>
}
    80004934:	60e2                	ld	ra,24(sp)
    80004936:	6442                	ld	s0,16(sp)
    80004938:	6105                	addi	sp,sp,32
    8000493a:	8082                	ret

000000008000493c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000493c:	1141                	addi	sp,sp,-16
    8000493e:	e406                	sd	ra,8(sp)
    80004940:	e022                	sd	s0,0(sp)
    80004942:	0800                	addi	s0,sp,16
    80004944:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004946:	4585                	li	a1,1
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	dc4080e7          	jalr	-572(ra) # 8000470c <namex>
}
    80004950:	60a2                	ld	ra,8(sp)
    80004952:	6402                	ld	s0,0(sp)
    80004954:	0141                	addi	sp,sp,16
    80004956:	8082                	ret

0000000080004958 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004958:	1101                	addi	sp,sp,-32
    8000495a:	ec06                	sd	ra,24(sp)
    8000495c:	e822                	sd	s0,16(sp)
    8000495e:	e426                	sd	s1,8(sp)
    80004960:	e04a                	sd	s2,0(sp)
    80004962:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004964:	0023f917          	auipc	s2,0x23f
    80004968:	11c90913          	addi	s2,s2,284 # 80243a80 <log>
    8000496c:	01892583          	lw	a1,24(s2)
    80004970:	02892503          	lw	a0,40(s2)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	fea080e7          	jalr	-22(ra) # 8000395e <bread>
    8000497c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000497e:	02c92683          	lw	a3,44(s2)
    80004982:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004984:	02d05763          	blez	a3,800049b2 <write_head+0x5a>
    80004988:	0023f797          	auipc	a5,0x23f
    8000498c:	12878793          	addi	a5,a5,296 # 80243ab0 <log+0x30>
    80004990:	05c50713          	addi	a4,a0,92
    80004994:	36fd                	addiw	a3,a3,-1
    80004996:	1682                	slli	a3,a3,0x20
    80004998:	9281                	srli	a3,a3,0x20
    8000499a:	068a                	slli	a3,a3,0x2
    8000499c:	0023f617          	auipc	a2,0x23f
    800049a0:	11860613          	addi	a2,a2,280 # 80243ab4 <log+0x34>
    800049a4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800049a6:	4390                	lw	a2,0(a5)
    800049a8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800049aa:	0791                	addi	a5,a5,4
    800049ac:	0711                	addi	a4,a4,4
    800049ae:	fed79ce3          	bne	a5,a3,800049a6 <write_head+0x4e>
  }
  bwrite(buf);
    800049b2:	8526                	mv	a0,s1
    800049b4:	fffff097          	auipc	ra,0xfffff
    800049b8:	09c080e7          	jalr	156(ra) # 80003a50 <bwrite>
  brelse(buf);
    800049bc:	8526                	mv	a0,s1
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	0d0080e7          	jalr	208(ra) # 80003a8e <brelse>
}
    800049c6:	60e2                	ld	ra,24(sp)
    800049c8:	6442                	ld	s0,16(sp)
    800049ca:	64a2                	ld	s1,8(sp)
    800049cc:	6902                	ld	s2,0(sp)
    800049ce:	6105                	addi	sp,sp,32
    800049d0:	8082                	ret

00000000800049d2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800049d2:	0023f797          	auipc	a5,0x23f
    800049d6:	0da7a783          	lw	a5,218(a5) # 80243aac <log+0x2c>
    800049da:	0af05d63          	blez	a5,80004a94 <install_trans+0xc2>
{
    800049de:	7139                	addi	sp,sp,-64
    800049e0:	fc06                	sd	ra,56(sp)
    800049e2:	f822                	sd	s0,48(sp)
    800049e4:	f426                	sd	s1,40(sp)
    800049e6:	f04a                	sd	s2,32(sp)
    800049e8:	ec4e                	sd	s3,24(sp)
    800049ea:	e852                	sd	s4,16(sp)
    800049ec:	e456                	sd	s5,8(sp)
    800049ee:	e05a                	sd	s6,0(sp)
    800049f0:	0080                	addi	s0,sp,64
    800049f2:	8b2a                	mv	s6,a0
    800049f4:	0023fa97          	auipc	s5,0x23f
    800049f8:	0bca8a93          	addi	s5,s5,188 # 80243ab0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049fc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800049fe:	0023f997          	auipc	s3,0x23f
    80004a02:	08298993          	addi	s3,s3,130 # 80243a80 <log>
    80004a06:	a035                	j	80004a32 <install_trans+0x60>
      bunpin(dbuf);
    80004a08:	8526                	mv	a0,s1
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	15e080e7          	jalr	350(ra) # 80003b68 <bunpin>
    brelse(lbuf);
    80004a12:	854a                	mv	a0,s2
    80004a14:	fffff097          	auipc	ra,0xfffff
    80004a18:	07a080e7          	jalr	122(ra) # 80003a8e <brelse>
    brelse(dbuf);
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	fffff097          	auipc	ra,0xfffff
    80004a22:	070080e7          	jalr	112(ra) # 80003a8e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a26:	2a05                	addiw	s4,s4,1
    80004a28:	0a91                	addi	s5,s5,4
    80004a2a:	02c9a783          	lw	a5,44(s3)
    80004a2e:	04fa5963          	bge	s4,a5,80004a80 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a32:	0189a583          	lw	a1,24(s3)
    80004a36:	014585bb          	addw	a1,a1,s4
    80004a3a:	2585                	addiw	a1,a1,1
    80004a3c:	0289a503          	lw	a0,40(s3)
    80004a40:	fffff097          	auipc	ra,0xfffff
    80004a44:	f1e080e7          	jalr	-226(ra) # 8000395e <bread>
    80004a48:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004a4a:	000aa583          	lw	a1,0(s5)
    80004a4e:	0289a503          	lw	a0,40(s3)
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	f0c080e7          	jalr	-244(ra) # 8000395e <bread>
    80004a5a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004a5c:	40000613          	li	a2,1024
    80004a60:	05890593          	addi	a1,s2,88
    80004a64:	05850513          	addi	a0,a0,88
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	41e080e7          	jalr	1054(ra) # 80000e86 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004a70:	8526                	mv	a0,s1
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	fde080e7          	jalr	-34(ra) # 80003a50 <bwrite>
    if(recovering == 0)
    80004a7a:	f80b1ce3          	bnez	s6,80004a12 <install_trans+0x40>
    80004a7e:	b769                	j	80004a08 <install_trans+0x36>
}
    80004a80:	70e2                	ld	ra,56(sp)
    80004a82:	7442                	ld	s0,48(sp)
    80004a84:	74a2                	ld	s1,40(sp)
    80004a86:	7902                	ld	s2,32(sp)
    80004a88:	69e2                	ld	s3,24(sp)
    80004a8a:	6a42                	ld	s4,16(sp)
    80004a8c:	6aa2                	ld	s5,8(sp)
    80004a8e:	6b02                	ld	s6,0(sp)
    80004a90:	6121                	addi	sp,sp,64
    80004a92:	8082                	ret
    80004a94:	8082                	ret

0000000080004a96 <initlog>:
{
    80004a96:	7179                	addi	sp,sp,-48
    80004a98:	f406                	sd	ra,40(sp)
    80004a9a:	f022                	sd	s0,32(sp)
    80004a9c:	ec26                	sd	s1,24(sp)
    80004a9e:	e84a                	sd	s2,16(sp)
    80004aa0:	e44e                	sd	s3,8(sp)
    80004aa2:	1800                	addi	s0,sp,48
    80004aa4:	892a                	mv	s2,a0
    80004aa6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004aa8:	0023f497          	auipc	s1,0x23f
    80004aac:	fd848493          	addi	s1,s1,-40 # 80243a80 <log>
    80004ab0:	00004597          	auipc	a1,0x4
    80004ab4:	e3058593          	addi	a1,a1,-464 # 800088e0 <syscalls+0x208>
    80004ab8:	8526                	mv	a0,s1
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	1e0080e7          	jalr	480(ra) # 80000c9a <initlock>
  log.start = sb->logstart;
    80004ac2:	0149a583          	lw	a1,20(s3)
    80004ac6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004ac8:	0109a783          	lw	a5,16(s3)
    80004acc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004ace:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004ad2:	854a                	mv	a0,s2
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	e8a080e7          	jalr	-374(ra) # 8000395e <bread>
  log.lh.n = lh->n;
    80004adc:	4d3c                	lw	a5,88(a0)
    80004ade:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004ae0:	02f05563          	blez	a5,80004b0a <initlog+0x74>
    80004ae4:	05c50713          	addi	a4,a0,92
    80004ae8:	0023f697          	auipc	a3,0x23f
    80004aec:	fc868693          	addi	a3,a3,-56 # 80243ab0 <log+0x30>
    80004af0:	37fd                	addiw	a5,a5,-1
    80004af2:	1782                	slli	a5,a5,0x20
    80004af4:	9381                	srli	a5,a5,0x20
    80004af6:	078a                	slli	a5,a5,0x2
    80004af8:	06050613          	addi	a2,a0,96
    80004afc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004afe:	4310                	lw	a2,0(a4)
    80004b00:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004b02:	0711                	addi	a4,a4,4
    80004b04:	0691                	addi	a3,a3,4
    80004b06:	fef71ce3          	bne	a4,a5,80004afe <initlog+0x68>
  brelse(buf);
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	f84080e7          	jalr	-124(ra) # 80003a8e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004b12:	4505                	li	a0,1
    80004b14:	00000097          	auipc	ra,0x0
    80004b18:	ebe080e7          	jalr	-322(ra) # 800049d2 <install_trans>
  log.lh.n = 0;
    80004b1c:	0023f797          	auipc	a5,0x23f
    80004b20:	f807a823          	sw	zero,-112(a5) # 80243aac <log+0x2c>
  write_head(); // clear the log
    80004b24:	00000097          	auipc	ra,0x0
    80004b28:	e34080e7          	jalr	-460(ra) # 80004958 <write_head>
}
    80004b2c:	70a2                	ld	ra,40(sp)
    80004b2e:	7402                	ld	s0,32(sp)
    80004b30:	64e2                	ld	s1,24(sp)
    80004b32:	6942                	ld	s2,16(sp)
    80004b34:	69a2                	ld	s3,8(sp)
    80004b36:	6145                	addi	sp,sp,48
    80004b38:	8082                	ret

0000000080004b3a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004b3a:	1101                	addi	sp,sp,-32
    80004b3c:	ec06                	sd	ra,24(sp)
    80004b3e:	e822                	sd	s0,16(sp)
    80004b40:	e426                	sd	s1,8(sp)
    80004b42:	e04a                	sd	s2,0(sp)
    80004b44:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004b46:	0023f517          	auipc	a0,0x23f
    80004b4a:	f3a50513          	addi	a0,a0,-198 # 80243a80 <log>
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	1dc080e7          	jalr	476(ra) # 80000d2a <acquire>
  while(1){
    if(log.committing){
    80004b56:	0023f497          	auipc	s1,0x23f
    80004b5a:	f2a48493          	addi	s1,s1,-214 # 80243a80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b5e:	4979                	li	s2,30
    80004b60:	a039                	j	80004b6e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004b62:	85a6                	mv	a1,s1
    80004b64:	8526                	mv	a0,s1
    80004b66:	ffffe097          	auipc	ra,0xffffe
    80004b6a:	b36080e7          	jalr	-1226(ra) # 8000269c <sleep>
    if(log.committing){
    80004b6e:	50dc                	lw	a5,36(s1)
    80004b70:	fbed                	bnez	a5,80004b62 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b72:	509c                	lw	a5,32(s1)
    80004b74:	0017871b          	addiw	a4,a5,1
    80004b78:	0007069b          	sext.w	a3,a4
    80004b7c:	0027179b          	slliw	a5,a4,0x2
    80004b80:	9fb9                	addw	a5,a5,a4
    80004b82:	0017979b          	slliw	a5,a5,0x1
    80004b86:	54d8                	lw	a4,44(s1)
    80004b88:	9fb9                	addw	a5,a5,a4
    80004b8a:	00f95963          	bge	s2,a5,80004b9c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004b8e:	85a6                	mv	a1,s1
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffe097          	auipc	ra,0xffffe
    80004b96:	b0a080e7          	jalr	-1270(ra) # 8000269c <sleep>
    80004b9a:	bfd1                	j	80004b6e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004b9c:	0023f517          	auipc	a0,0x23f
    80004ba0:	ee450513          	addi	a0,a0,-284 # 80243a80 <log>
    80004ba4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	238080e7          	jalr	568(ra) # 80000dde <release>
      break;
    }
  }
}
    80004bae:	60e2                	ld	ra,24(sp)
    80004bb0:	6442                	ld	s0,16(sp)
    80004bb2:	64a2                	ld	s1,8(sp)
    80004bb4:	6902                	ld	s2,0(sp)
    80004bb6:	6105                	addi	sp,sp,32
    80004bb8:	8082                	ret

0000000080004bba <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004bba:	7139                	addi	sp,sp,-64
    80004bbc:	fc06                	sd	ra,56(sp)
    80004bbe:	f822                	sd	s0,48(sp)
    80004bc0:	f426                	sd	s1,40(sp)
    80004bc2:	f04a                	sd	s2,32(sp)
    80004bc4:	ec4e                	sd	s3,24(sp)
    80004bc6:	e852                	sd	s4,16(sp)
    80004bc8:	e456                	sd	s5,8(sp)
    80004bca:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004bcc:	0023f497          	auipc	s1,0x23f
    80004bd0:	eb448493          	addi	s1,s1,-332 # 80243a80 <log>
    80004bd4:	8526                	mv	a0,s1
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	154080e7          	jalr	340(ra) # 80000d2a <acquire>
  log.outstanding -= 1;
    80004bde:	509c                	lw	a5,32(s1)
    80004be0:	37fd                	addiw	a5,a5,-1
    80004be2:	0007891b          	sext.w	s2,a5
    80004be6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004be8:	50dc                	lw	a5,36(s1)
    80004bea:	efb9                	bnez	a5,80004c48 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004bec:	06091663          	bnez	s2,80004c58 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004bf0:	0023f497          	auipc	s1,0x23f
    80004bf4:	e9048493          	addi	s1,s1,-368 # 80243a80 <log>
    80004bf8:	4785                	li	a5,1
    80004bfa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	1e0080e7          	jalr	480(ra) # 80000dde <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004c06:	54dc                	lw	a5,44(s1)
    80004c08:	06f04763          	bgtz	a5,80004c76 <end_op+0xbc>
    acquire(&log.lock);
    80004c0c:	0023f497          	auipc	s1,0x23f
    80004c10:	e7448493          	addi	s1,s1,-396 # 80243a80 <log>
    80004c14:	8526                	mv	a0,s1
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	114080e7          	jalr	276(ra) # 80000d2a <acquire>
    log.committing = 0;
    80004c1e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004c22:	8526                	mv	a0,s1
    80004c24:	ffffe097          	auipc	ra,0xffffe
    80004c28:	d54080e7          	jalr	-684(ra) # 80002978 <wakeup>
    release(&log.lock);
    80004c2c:	8526                	mv	a0,s1
    80004c2e:	ffffc097          	auipc	ra,0xffffc
    80004c32:	1b0080e7          	jalr	432(ra) # 80000dde <release>
}
    80004c36:	70e2                	ld	ra,56(sp)
    80004c38:	7442                	ld	s0,48(sp)
    80004c3a:	74a2                	ld	s1,40(sp)
    80004c3c:	7902                	ld	s2,32(sp)
    80004c3e:	69e2                	ld	s3,24(sp)
    80004c40:	6a42                	ld	s4,16(sp)
    80004c42:	6aa2                	ld	s5,8(sp)
    80004c44:	6121                	addi	sp,sp,64
    80004c46:	8082                	ret
    panic("log.committing");
    80004c48:	00004517          	auipc	a0,0x4
    80004c4c:	ca050513          	addi	a0,a0,-864 # 800088e8 <syscalls+0x210>
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	8f4080e7          	jalr	-1804(ra) # 80000544 <panic>
    wakeup(&log);
    80004c58:	0023f497          	auipc	s1,0x23f
    80004c5c:	e2848493          	addi	s1,s1,-472 # 80243a80 <log>
    80004c60:	8526                	mv	a0,s1
    80004c62:	ffffe097          	auipc	ra,0xffffe
    80004c66:	d16080e7          	jalr	-746(ra) # 80002978 <wakeup>
  release(&log.lock);
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	172080e7          	jalr	370(ra) # 80000dde <release>
  if(do_commit){
    80004c74:	b7c9                	j	80004c36 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c76:	0023fa97          	auipc	s5,0x23f
    80004c7a:	e3aa8a93          	addi	s5,s5,-454 # 80243ab0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004c7e:	0023fa17          	auipc	s4,0x23f
    80004c82:	e02a0a13          	addi	s4,s4,-510 # 80243a80 <log>
    80004c86:	018a2583          	lw	a1,24(s4)
    80004c8a:	012585bb          	addw	a1,a1,s2
    80004c8e:	2585                	addiw	a1,a1,1
    80004c90:	028a2503          	lw	a0,40(s4)
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	cca080e7          	jalr	-822(ra) # 8000395e <bread>
    80004c9c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004c9e:	000aa583          	lw	a1,0(s5)
    80004ca2:	028a2503          	lw	a0,40(s4)
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	cb8080e7          	jalr	-840(ra) # 8000395e <bread>
    80004cae:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004cb0:	40000613          	li	a2,1024
    80004cb4:	05850593          	addi	a1,a0,88
    80004cb8:	05848513          	addi	a0,s1,88
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	1ca080e7          	jalr	458(ra) # 80000e86 <memmove>
    bwrite(to);  // write the log
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	d8a080e7          	jalr	-630(ra) # 80003a50 <bwrite>
    brelse(from);
    80004cce:	854e                	mv	a0,s3
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	dbe080e7          	jalr	-578(ra) # 80003a8e <brelse>
    brelse(to);
    80004cd8:	8526                	mv	a0,s1
    80004cda:	fffff097          	auipc	ra,0xfffff
    80004cde:	db4080e7          	jalr	-588(ra) # 80003a8e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ce2:	2905                	addiw	s2,s2,1
    80004ce4:	0a91                	addi	s5,s5,4
    80004ce6:	02ca2783          	lw	a5,44(s4)
    80004cea:	f8f94ee3          	blt	s2,a5,80004c86 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004cee:	00000097          	auipc	ra,0x0
    80004cf2:	c6a080e7          	jalr	-918(ra) # 80004958 <write_head>
    install_trans(0); // Now install writes to home locations
    80004cf6:	4501                	li	a0,0
    80004cf8:	00000097          	auipc	ra,0x0
    80004cfc:	cda080e7          	jalr	-806(ra) # 800049d2 <install_trans>
    log.lh.n = 0;
    80004d00:	0023f797          	auipc	a5,0x23f
    80004d04:	da07a623          	sw	zero,-596(a5) # 80243aac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004d08:	00000097          	auipc	ra,0x0
    80004d0c:	c50080e7          	jalr	-944(ra) # 80004958 <write_head>
    80004d10:	bdf5                	j	80004c0c <end_op+0x52>

0000000080004d12 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004d12:	1101                	addi	sp,sp,-32
    80004d14:	ec06                	sd	ra,24(sp)
    80004d16:	e822                	sd	s0,16(sp)
    80004d18:	e426                	sd	s1,8(sp)
    80004d1a:	e04a                	sd	s2,0(sp)
    80004d1c:	1000                	addi	s0,sp,32
    80004d1e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004d20:	0023f917          	auipc	s2,0x23f
    80004d24:	d6090913          	addi	s2,s2,-672 # 80243a80 <log>
    80004d28:	854a                	mv	a0,s2
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	000080e7          	jalr	ra # 80000d2a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004d32:	02c92603          	lw	a2,44(s2)
    80004d36:	47f5                	li	a5,29
    80004d38:	06c7c563          	blt	a5,a2,80004da2 <log_write+0x90>
    80004d3c:	0023f797          	auipc	a5,0x23f
    80004d40:	d607a783          	lw	a5,-672(a5) # 80243a9c <log+0x1c>
    80004d44:	37fd                	addiw	a5,a5,-1
    80004d46:	04f65e63          	bge	a2,a5,80004da2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004d4a:	0023f797          	auipc	a5,0x23f
    80004d4e:	d567a783          	lw	a5,-682(a5) # 80243aa0 <log+0x20>
    80004d52:	06f05063          	blez	a5,80004db2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004d56:	4781                	li	a5,0
    80004d58:	06c05563          	blez	a2,80004dc2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d5c:	44cc                	lw	a1,12(s1)
    80004d5e:	0023f717          	auipc	a4,0x23f
    80004d62:	d5270713          	addi	a4,a4,-686 # 80243ab0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004d66:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d68:	4314                	lw	a3,0(a4)
    80004d6a:	04b68c63          	beq	a3,a1,80004dc2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004d6e:	2785                	addiw	a5,a5,1
    80004d70:	0711                	addi	a4,a4,4
    80004d72:	fef61be3          	bne	a2,a5,80004d68 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004d76:	0621                	addi	a2,a2,8
    80004d78:	060a                	slli	a2,a2,0x2
    80004d7a:	0023f797          	auipc	a5,0x23f
    80004d7e:	d0678793          	addi	a5,a5,-762 # 80243a80 <log>
    80004d82:	963e                	add	a2,a2,a5
    80004d84:	44dc                	lw	a5,12(s1)
    80004d86:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004d88:	8526                	mv	a0,s1
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	da2080e7          	jalr	-606(ra) # 80003b2c <bpin>
    log.lh.n++;
    80004d92:	0023f717          	auipc	a4,0x23f
    80004d96:	cee70713          	addi	a4,a4,-786 # 80243a80 <log>
    80004d9a:	575c                	lw	a5,44(a4)
    80004d9c:	2785                	addiw	a5,a5,1
    80004d9e:	d75c                	sw	a5,44(a4)
    80004da0:	a835                	j	80004ddc <log_write+0xca>
    panic("too big a transaction");
    80004da2:	00004517          	auipc	a0,0x4
    80004da6:	b5650513          	addi	a0,a0,-1194 # 800088f8 <syscalls+0x220>
    80004daa:	ffffb097          	auipc	ra,0xffffb
    80004dae:	79a080e7          	jalr	1946(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004db2:	00004517          	auipc	a0,0x4
    80004db6:	b5e50513          	addi	a0,a0,-1186 # 80008910 <syscalls+0x238>
    80004dba:	ffffb097          	auipc	ra,0xffffb
    80004dbe:	78a080e7          	jalr	1930(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004dc2:	00878713          	addi	a4,a5,8
    80004dc6:	00271693          	slli	a3,a4,0x2
    80004dca:	0023f717          	auipc	a4,0x23f
    80004dce:	cb670713          	addi	a4,a4,-842 # 80243a80 <log>
    80004dd2:	9736                	add	a4,a4,a3
    80004dd4:	44d4                	lw	a3,12(s1)
    80004dd6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004dd8:	faf608e3          	beq	a2,a5,80004d88 <log_write+0x76>
  }
  release(&log.lock);
    80004ddc:	0023f517          	auipc	a0,0x23f
    80004de0:	ca450513          	addi	a0,a0,-860 # 80243a80 <log>
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	ffa080e7          	jalr	-6(ra) # 80000dde <release>
}
    80004dec:	60e2                	ld	ra,24(sp)
    80004dee:	6442                	ld	s0,16(sp)
    80004df0:	64a2                	ld	s1,8(sp)
    80004df2:	6902                	ld	s2,0(sp)
    80004df4:	6105                	addi	sp,sp,32
    80004df6:	8082                	ret

0000000080004df8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004df8:	1101                	addi	sp,sp,-32
    80004dfa:	ec06                	sd	ra,24(sp)
    80004dfc:	e822                	sd	s0,16(sp)
    80004dfe:	e426                	sd	s1,8(sp)
    80004e00:	e04a                	sd	s2,0(sp)
    80004e02:	1000                	addi	s0,sp,32
    80004e04:	84aa                	mv	s1,a0
    80004e06:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004e08:	00004597          	auipc	a1,0x4
    80004e0c:	b2858593          	addi	a1,a1,-1240 # 80008930 <syscalls+0x258>
    80004e10:	0521                	addi	a0,a0,8
    80004e12:	ffffc097          	auipc	ra,0xffffc
    80004e16:	e88080e7          	jalr	-376(ra) # 80000c9a <initlock>
  lk->name = name;
    80004e1a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004e1e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e22:	0204a423          	sw	zero,40(s1)
}
    80004e26:	60e2                	ld	ra,24(sp)
    80004e28:	6442                	ld	s0,16(sp)
    80004e2a:	64a2                	ld	s1,8(sp)
    80004e2c:	6902                	ld	s2,0(sp)
    80004e2e:	6105                	addi	sp,sp,32
    80004e30:	8082                	ret

0000000080004e32 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004e32:	1101                	addi	sp,sp,-32
    80004e34:	ec06                	sd	ra,24(sp)
    80004e36:	e822                	sd	s0,16(sp)
    80004e38:	e426                	sd	s1,8(sp)
    80004e3a:	e04a                	sd	s2,0(sp)
    80004e3c:	1000                	addi	s0,sp,32
    80004e3e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e40:	00850913          	addi	s2,a0,8
    80004e44:	854a                	mv	a0,s2
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	ee4080e7          	jalr	-284(ra) # 80000d2a <acquire>
  while (lk->locked) {
    80004e4e:	409c                	lw	a5,0(s1)
    80004e50:	cb89                	beqz	a5,80004e62 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004e52:	85ca                	mv	a1,s2
    80004e54:	8526                	mv	a0,s1
    80004e56:	ffffe097          	auipc	ra,0xffffe
    80004e5a:	846080e7          	jalr	-1978(ra) # 8000269c <sleep>
  while (lk->locked) {
    80004e5e:	409c                	lw	a5,0(s1)
    80004e60:	fbed                	bnez	a5,80004e52 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004e62:	4785                	li	a5,1
    80004e64:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004e66:	ffffd097          	auipc	ra,0xffffd
    80004e6a:	ef8080e7          	jalr	-264(ra) # 80001d5e <myproc>
    80004e6e:	591c                	lw	a5,48(a0)
    80004e70:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004e72:	854a                	mv	a0,s2
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	f6a080e7          	jalr	-150(ra) # 80000dde <release>
}
    80004e7c:	60e2                	ld	ra,24(sp)
    80004e7e:	6442                	ld	s0,16(sp)
    80004e80:	64a2                	ld	s1,8(sp)
    80004e82:	6902                	ld	s2,0(sp)
    80004e84:	6105                	addi	sp,sp,32
    80004e86:	8082                	ret

0000000080004e88 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004e88:	1101                	addi	sp,sp,-32
    80004e8a:	ec06                	sd	ra,24(sp)
    80004e8c:	e822                	sd	s0,16(sp)
    80004e8e:	e426                	sd	s1,8(sp)
    80004e90:	e04a                	sd	s2,0(sp)
    80004e92:	1000                	addi	s0,sp,32
    80004e94:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e96:	00850913          	addi	s2,a0,8
    80004e9a:	854a                	mv	a0,s2
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	e8e080e7          	jalr	-370(ra) # 80000d2a <acquire>
  lk->locked = 0;
    80004ea4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ea8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004eac:	8526                	mv	a0,s1
    80004eae:	ffffe097          	auipc	ra,0xffffe
    80004eb2:	aca080e7          	jalr	-1334(ra) # 80002978 <wakeup>
  release(&lk->lk);
    80004eb6:	854a                	mv	a0,s2
    80004eb8:	ffffc097          	auipc	ra,0xffffc
    80004ebc:	f26080e7          	jalr	-218(ra) # 80000dde <release>
}
    80004ec0:	60e2                	ld	ra,24(sp)
    80004ec2:	6442                	ld	s0,16(sp)
    80004ec4:	64a2                	ld	s1,8(sp)
    80004ec6:	6902                	ld	s2,0(sp)
    80004ec8:	6105                	addi	sp,sp,32
    80004eca:	8082                	ret

0000000080004ecc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ecc:	7179                	addi	sp,sp,-48
    80004ece:	f406                	sd	ra,40(sp)
    80004ed0:	f022                	sd	s0,32(sp)
    80004ed2:	ec26                	sd	s1,24(sp)
    80004ed4:	e84a                	sd	s2,16(sp)
    80004ed6:	e44e                	sd	s3,8(sp)
    80004ed8:	1800                	addi	s0,sp,48
    80004eda:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004edc:	00850913          	addi	s2,a0,8
    80004ee0:	854a                	mv	a0,s2
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	e48080e7          	jalr	-440(ra) # 80000d2a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004eea:	409c                	lw	a5,0(s1)
    80004eec:	ef99                	bnez	a5,80004f0a <holdingsleep+0x3e>
    80004eee:	4481                	li	s1,0
  release(&lk->lk);
    80004ef0:	854a                	mv	a0,s2
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	eec080e7          	jalr	-276(ra) # 80000dde <release>
  return r;
}
    80004efa:	8526                	mv	a0,s1
    80004efc:	70a2                	ld	ra,40(sp)
    80004efe:	7402                	ld	s0,32(sp)
    80004f00:	64e2                	ld	s1,24(sp)
    80004f02:	6942                	ld	s2,16(sp)
    80004f04:	69a2                	ld	s3,8(sp)
    80004f06:	6145                	addi	sp,sp,48
    80004f08:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f0a:	0284a983          	lw	s3,40(s1)
    80004f0e:	ffffd097          	auipc	ra,0xffffd
    80004f12:	e50080e7          	jalr	-432(ra) # 80001d5e <myproc>
    80004f16:	5904                	lw	s1,48(a0)
    80004f18:	413484b3          	sub	s1,s1,s3
    80004f1c:	0014b493          	seqz	s1,s1
    80004f20:	bfc1                	j	80004ef0 <holdingsleep+0x24>

0000000080004f22 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004f22:	1141                	addi	sp,sp,-16
    80004f24:	e406                	sd	ra,8(sp)
    80004f26:	e022                	sd	s0,0(sp)
    80004f28:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004f2a:	00004597          	auipc	a1,0x4
    80004f2e:	a1658593          	addi	a1,a1,-1514 # 80008940 <syscalls+0x268>
    80004f32:	0023f517          	auipc	a0,0x23f
    80004f36:	c9650513          	addi	a0,a0,-874 # 80243bc8 <ftable>
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	d60080e7          	jalr	-672(ra) # 80000c9a <initlock>
}
    80004f42:	60a2                	ld	ra,8(sp)
    80004f44:	6402                	ld	s0,0(sp)
    80004f46:	0141                	addi	sp,sp,16
    80004f48:	8082                	ret

0000000080004f4a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004f4a:	1101                	addi	sp,sp,-32
    80004f4c:	ec06                	sd	ra,24(sp)
    80004f4e:	e822                	sd	s0,16(sp)
    80004f50:	e426                	sd	s1,8(sp)
    80004f52:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004f54:	0023f517          	auipc	a0,0x23f
    80004f58:	c7450513          	addi	a0,a0,-908 # 80243bc8 <ftable>
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	dce080e7          	jalr	-562(ra) # 80000d2a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f64:	0023f497          	auipc	s1,0x23f
    80004f68:	c7c48493          	addi	s1,s1,-900 # 80243be0 <ftable+0x18>
    80004f6c:	00240717          	auipc	a4,0x240
    80004f70:	c1470713          	addi	a4,a4,-1004 # 80244b80 <disk>
    if(f->ref == 0){
    80004f74:	40dc                	lw	a5,4(s1)
    80004f76:	cf99                	beqz	a5,80004f94 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f78:	02848493          	addi	s1,s1,40
    80004f7c:	fee49ce3          	bne	s1,a4,80004f74 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004f80:	0023f517          	auipc	a0,0x23f
    80004f84:	c4850513          	addi	a0,a0,-952 # 80243bc8 <ftable>
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	e56080e7          	jalr	-426(ra) # 80000dde <release>
  return 0;
    80004f90:	4481                	li	s1,0
    80004f92:	a819                	j	80004fa8 <filealloc+0x5e>
      f->ref = 1;
    80004f94:	4785                	li	a5,1
    80004f96:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004f98:	0023f517          	auipc	a0,0x23f
    80004f9c:	c3050513          	addi	a0,a0,-976 # 80243bc8 <ftable>
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	e3e080e7          	jalr	-450(ra) # 80000dde <release>
}
    80004fa8:	8526                	mv	a0,s1
    80004faa:	60e2                	ld	ra,24(sp)
    80004fac:	6442                	ld	s0,16(sp)
    80004fae:	64a2                	ld	s1,8(sp)
    80004fb0:	6105                	addi	sp,sp,32
    80004fb2:	8082                	ret

0000000080004fb4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004fb4:	1101                	addi	sp,sp,-32
    80004fb6:	ec06                	sd	ra,24(sp)
    80004fb8:	e822                	sd	s0,16(sp)
    80004fba:	e426                	sd	s1,8(sp)
    80004fbc:	1000                	addi	s0,sp,32
    80004fbe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004fc0:	0023f517          	auipc	a0,0x23f
    80004fc4:	c0850513          	addi	a0,a0,-1016 # 80243bc8 <ftable>
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	d62080e7          	jalr	-670(ra) # 80000d2a <acquire>
  if(f->ref < 1)
    80004fd0:	40dc                	lw	a5,4(s1)
    80004fd2:	02f05263          	blez	a5,80004ff6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004fd6:	2785                	addiw	a5,a5,1
    80004fd8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004fda:	0023f517          	auipc	a0,0x23f
    80004fde:	bee50513          	addi	a0,a0,-1042 # 80243bc8 <ftable>
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	dfc080e7          	jalr	-516(ra) # 80000dde <release>
  return f;
}
    80004fea:	8526                	mv	a0,s1
    80004fec:	60e2                	ld	ra,24(sp)
    80004fee:	6442                	ld	s0,16(sp)
    80004ff0:	64a2                	ld	s1,8(sp)
    80004ff2:	6105                	addi	sp,sp,32
    80004ff4:	8082                	ret
    panic("filedup");
    80004ff6:	00004517          	auipc	a0,0x4
    80004ffa:	95250513          	addi	a0,a0,-1710 # 80008948 <syscalls+0x270>
    80004ffe:	ffffb097          	auipc	ra,0xffffb
    80005002:	546080e7          	jalr	1350(ra) # 80000544 <panic>

0000000080005006 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005006:	7139                	addi	sp,sp,-64
    80005008:	fc06                	sd	ra,56(sp)
    8000500a:	f822                	sd	s0,48(sp)
    8000500c:	f426                	sd	s1,40(sp)
    8000500e:	f04a                	sd	s2,32(sp)
    80005010:	ec4e                	sd	s3,24(sp)
    80005012:	e852                	sd	s4,16(sp)
    80005014:	e456                	sd	s5,8(sp)
    80005016:	0080                	addi	s0,sp,64
    80005018:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000501a:	0023f517          	auipc	a0,0x23f
    8000501e:	bae50513          	addi	a0,a0,-1106 # 80243bc8 <ftable>
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	d08080e7          	jalr	-760(ra) # 80000d2a <acquire>
  if(f->ref < 1)
    8000502a:	40dc                	lw	a5,4(s1)
    8000502c:	06f05163          	blez	a5,8000508e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005030:	37fd                	addiw	a5,a5,-1
    80005032:	0007871b          	sext.w	a4,a5
    80005036:	c0dc                	sw	a5,4(s1)
    80005038:	06e04363          	bgtz	a4,8000509e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000503c:	0004a903          	lw	s2,0(s1)
    80005040:	0094ca83          	lbu	s5,9(s1)
    80005044:	0104ba03          	ld	s4,16(s1)
    80005048:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000504c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005050:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005054:	0023f517          	auipc	a0,0x23f
    80005058:	b7450513          	addi	a0,a0,-1164 # 80243bc8 <ftable>
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	d82080e7          	jalr	-638(ra) # 80000dde <release>

  if(ff.type == FD_PIPE){
    80005064:	4785                	li	a5,1
    80005066:	04f90d63          	beq	s2,a5,800050c0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000506a:	3979                	addiw	s2,s2,-2
    8000506c:	4785                	li	a5,1
    8000506e:	0527e063          	bltu	a5,s2,800050ae <fileclose+0xa8>
    begin_op();
    80005072:	00000097          	auipc	ra,0x0
    80005076:	ac8080e7          	jalr	-1336(ra) # 80004b3a <begin_op>
    iput(ff.ip);
    8000507a:	854e                	mv	a0,s3
    8000507c:	fffff097          	auipc	ra,0xfffff
    80005080:	2b6080e7          	jalr	694(ra) # 80004332 <iput>
    end_op();
    80005084:	00000097          	auipc	ra,0x0
    80005088:	b36080e7          	jalr	-1226(ra) # 80004bba <end_op>
    8000508c:	a00d                	j	800050ae <fileclose+0xa8>
    panic("fileclose");
    8000508e:	00004517          	auipc	a0,0x4
    80005092:	8c250513          	addi	a0,a0,-1854 # 80008950 <syscalls+0x278>
    80005096:	ffffb097          	auipc	ra,0xffffb
    8000509a:	4ae080e7          	jalr	1198(ra) # 80000544 <panic>
    release(&ftable.lock);
    8000509e:	0023f517          	auipc	a0,0x23f
    800050a2:	b2a50513          	addi	a0,a0,-1238 # 80243bc8 <ftable>
    800050a6:	ffffc097          	auipc	ra,0xffffc
    800050aa:	d38080e7          	jalr	-712(ra) # 80000dde <release>
  }
}
    800050ae:	70e2                	ld	ra,56(sp)
    800050b0:	7442                	ld	s0,48(sp)
    800050b2:	74a2                	ld	s1,40(sp)
    800050b4:	7902                	ld	s2,32(sp)
    800050b6:	69e2                	ld	s3,24(sp)
    800050b8:	6a42                	ld	s4,16(sp)
    800050ba:	6aa2                	ld	s5,8(sp)
    800050bc:	6121                	addi	sp,sp,64
    800050be:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800050c0:	85d6                	mv	a1,s5
    800050c2:	8552                	mv	a0,s4
    800050c4:	00000097          	auipc	ra,0x0
    800050c8:	34c080e7          	jalr	844(ra) # 80005410 <pipeclose>
    800050cc:	b7cd                	j	800050ae <fileclose+0xa8>

00000000800050ce <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800050ce:	715d                	addi	sp,sp,-80
    800050d0:	e486                	sd	ra,72(sp)
    800050d2:	e0a2                	sd	s0,64(sp)
    800050d4:	fc26                	sd	s1,56(sp)
    800050d6:	f84a                	sd	s2,48(sp)
    800050d8:	f44e                	sd	s3,40(sp)
    800050da:	0880                	addi	s0,sp,80
    800050dc:	84aa                	mv	s1,a0
    800050de:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800050e0:	ffffd097          	auipc	ra,0xffffd
    800050e4:	c7e080e7          	jalr	-898(ra) # 80001d5e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800050e8:	409c                	lw	a5,0(s1)
    800050ea:	37f9                	addiw	a5,a5,-2
    800050ec:	4705                	li	a4,1
    800050ee:	04f76763          	bltu	a4,a5,8000513c <filestat+0x6e>
    800050f2:	892a                	mv	s2,a0
    ilock(f->ip);
    800050f4:	6c88                	ld	a0,24(s1)
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	082080e7          	jalr	130(ra) # 80004178 <ilock>
    stati(f->ip, &st);
    800050fe:	fb840593          	addi	a1,s0,-72
    80005102:	6c88                	ld	a0,24(s1)
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	2fe080e7          	jalr	766(ra) # 80004402 <stati>
    iunlock(f->ip);
    8000510c:	6c88                	ld	a0,24(s1)
    8000510e:	fffff097          	auipc	ra,0xfffff
    80005112:	12c080e7          	jalr	300(ra) # 8000423a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005116:	46e1                	li	a3,24
    80005118:	fb840613          	addi	a2,s0,-72
    8000511c:	85ce                	mv	a1,s3
    8000511e:	05093503          	ld	a0,80(s2)
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	688080e7          	jalr	1672(ra) # 800017aa <copyout>
    8000512a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000512e:	60a6                	ld	ra,72(sp)
    80005130:	6406                	ld	s0,64(sp)
    80005132:	74e2                	ld	s1,56(sp)
    80005134:	7942                	ld	s2,48(sp)
    80005136:	79a2                	ld	s3,40(sp)
    80005138:	6161                	addi	sp,sp,80
    8000513a:	8082                	ret
  return -1;
    8000513c:	557d                	li	a0,-1
    8000513e:	bfc5                	j	8000512e <filestat+0x60>

0000000080005140 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005140:	7179                	addi	sp,sp,-48
    80005142:	f406                	sd	ra,40(sp)
    80005144:	f022                	sd	s0,32(sp)
    80005146:	ec26                	sd	s1,24(sp)
    80005148:	e84a                	sd	s2,16(sp)
    8000514a:	e44e                	sd	s3,8(sp)
    8000514c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000514e:	00854783          	lbu	a5,8(a0)
    80005152:	c3d5                	beqz	a5,800051f6 <fileread+0xb6>
    80005154:	84aa                	mv	s1,a0
    80005156:	89ae                	mv	s3,a1
    80005158:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000515a:	411c                	lw	a5,0(a0)
    8000515c:	4705                	li	a4,1
    8000515e:	04e78963          	beq	a5,a4,800051b0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005162:	470d                	li	a4,3
    80005164:	04e78d63          	beq	a5,a4,800051be <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005168:	4709                	li	a4,2
    8000516a:	06e79e63          	bne	a5,a4,800051e6 <fileread+0xa6>
    ilock(f->ip);
    8000516e:	6d08                	ld	a0,24(a0)
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	008080e7          	jalr	8(ra) # 80004178 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005178:	874a                	mv	a4,s2
    8000517a:	5094                	lw	a3,32(s1)
    8000517c:	864e                	mv	a2,s3
    8000517e:	4585                	li	a1,1
    80005180:	6c88                	ld	a0,24(s1)
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	2aa080e7          	jalr	682(ra) # 8000442c <readi>
    8000518a:	892a                	mv	s2,a0
    8000518c:	00a05563          	blez	a0,80005196 <fileread+0x56>
      f->off += r;
    80005190:	509c                	lw	a5,32(s1)
    80005192:	9fa9                	addw	a5,a5,a0
    80005194:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005196:	6c88                	ld	a0,24(s1)
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	0a2080e7          	jalr	162(ra) # 8000423a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800051a0:	854a                	mv	a0,s2
    800051a2:	70a2                	ld	ra,40(sp)
    800051a4:	7402                	ld	s0,32(sp)
    800051a6:	64e2                	ld	s1,24(sp)
    800051a8:	6942                	ld	s2,16(sp)
    800051aa:	69a2                	ld	s3,8(sp)
    800051ac:	6145                	addi	sp,sp,48
    800051ae:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800051b0:	6908                	ld	a0,16(a0)
    800051b2:	00000097          	auipc	ra,0x0
    800051b6:	3ce080e7          	jalr	974(ra) # 80005580 <piperead>
    800051ba:	892a                	mv	s2,a0
    800051bc:	b7d5                	j	800051a0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800051be:	02451783          	lh	a5,36(a0)
    800051c2:	03079693          	slli	a3,a5,0x30
    800051c6:	92c1                	srli	a3,a3,0x30
    800051c8:	4725                	li	a4,9
    800051ca:	02d76863          	bltu	a4,a3,800051fa <fileread+0xba>
    800051ce:	0792                	slli	a5,a5,0x4
    800051d0:	0023f717          	auipc	a4,0x23f
    800051d4:	95870713          	addi	a4,a4,-1704 # 80243b28 <devsw>
    800051d8:	97ba                	add	a5,a5,a4
    800051da:	639c                	ld	a5,0(a5)
    800051dc:	c38d                	beqz	a5,800051fe <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800051de:	4505                	li	a0,1
    800051e0:	9782                	jalr	a5
    800051e2:	892a                	mv	s2,a0
    800051e4:	bf75                	j	800051a0 <fileread+0x60>
    panic("fileread");
    800051e6:	00003517          	auipc	a0,0x3
    800051ea:	77a50513          	addi	a0,a0,1914 # 80008960 <syscalls+0x288>
    800051ee:	ffffb097          	auipc	ra,0xffffb
    800051f2:	356080e7          	jalr	854(ra) # 80000544 <panic>
    return -1;
    800051f6:	597d                	li	s2,-1
    800051f8:	b765                	j	800051a0 <fileread+0x60>
      return -1;
    800051fa:	597d                	li	s2,-1
    800051fc:	b755                	j	800051a0 <fileread+0x60>
    800051fe:	597d                	li	s2,-1
    80005200:	b745                	j	800051a0 <fileread+0x60>

0000000080005202 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005202:	715d                	addi	sp,sp,-80
    80005204:	e486                	sd	ra,72(sp)
    80005206:	e0a2                	sd	s0,64(sp)
    80005208:	fc26                	sd	s1,56(sp)
    8000520a:	f84a                	sd	s2,48(sp)
    8000520c:	f44e                	sd	s3,40(sp)
    8000520e:	f052                	sd	s4,32(sp)
    80005210:	ec56                	sd	s5,24(sp)
    80005212:	e85a                	sd	s6,16(sp)
    80005214:	e45e                	sd	s7,8(sp)
    80005216:	e062                	sd	s8,0(sp)
    80005218:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000521a:	00954783          	lbu	a5,9(a0)
    8000521e:	10078663          	beqz	a5,8000532a <filewrite+0x128>
    80005222:	892a                	mv	s2,a0
    80005224:	8aae                	mv	s5,a1
    80005226:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005228:	411c                	lw	a5,0(a0)
    8000522a:	4705                	li	a4,1
    8000522c:	02e78263          	beq	a5,a4,80005250 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005230:	470d                	li	a4,3
    80005232:	02e78663          	beq	a5,a4,8000525e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005236:	4709                	li	a4,2
    80005238:	0ee79163          	bne	a5,a4,8000531a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000523c:	0ac05d63          	blez	a2,800052f6 <filewrite+0xf4>
    int i = 0;
    80005240:	4981                	li	s3,0
    80005242:	6b05                	lui	s6,0x1
    80005244:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005248:	6b85                	lui	s7,0x1
    8000524a:	c00b8b9b          	addiw	s7,s7,-1024
    8000524e:	a861                	j	800052e6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005250:	6908                	ld	a0,16(a0)
    80005252:	00000097          	auipc	ra,0x0
    80005256:	22e080e7          	jalr	558(ra) # 80005480 <pipewrite>
    8000525a:	8a2a                	mv	s4,a0
    8000525c:	a045                	j	800052fc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000525e:	02451783          	lh	a5,36(a0)
    80005262:	03079693          	slli	a3,a5,0x30
    80005266:	92c1                	srli	a3,a3,0x30
    80005268:	4725                	li	a4,9
    8000526a:	0cd76263          	bltu	a4,a3,8000532e <filewrite+0x12c>
    8000526e:	0792                	slli	a5,a5,0x4
    80005270:	0023f717          	auipc	a4,0x23f
    80005274:	8b870713          	addi	a4,a4,-1864 # 80243b28 <devsw>
    80005278:	97ba                	add	a5,a5,a4
    8000527a:	679c                	ld	a5,8(a5)
    8000527c:	cbdd                	beqz	a5,80005332 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000527e:	4505                	li	a0,1
    80005280:	9782                	jalr	a5
    80005282:	8a2a                	mv	s4,a0
    80005284:	a8a5                	j	800052fc <filewrite+0xfa>
    80005286:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000528a:	00000097          	auipc	ra,0x0
    8000528e:	8b0080e7          	jalr	-1872(ra) # 80004b3a <begin_op>
      ilock(f->ip);
    80005292:	01893503          	ld	a0,24(s2)
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	ee2080e7          	jalr	-286(ra) # 80004178 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000529e:	8762                	mv	a4,s8
    800052a0:	02092683          	lw	a3,32(s2)
    800052a4:	01598633          	add	a2,s3,s5
    800052a8:	4585                	li	a1,1
    800052aa:	01893503          	ld	a0,24(s2)
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	276080e7          	jalr	630(ra) # 80004524 <writei>
    800052b6:	84aa                	mv	s1,a0
    800052b8:	00a05763          	blez	a0,800052c6 <filewrite+0xc4>
        f->off += r;
    800052bc:	02092783          	lw	a5,32(s2)
    800052c0:	9fa9                	addw	a5,a5,a0
    800052c2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800052c6:	01893503          	ld	a0,24(s2)
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	f70080e7          	jalr	-144(ra) # 8000423a <iunlock>
      end_op();
    800052d2:	00000097          	auipc	ra,0x0
    800052d6:	8e8080e7          	jalr	-1816(ra) # 80004bba <end_op>

      if(r != n1){
    800052da:	009c1f63          	bne	s8,s1,800052f8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800052de:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800052e2:	0149db63          	bge	s3,s4,800052f8 <filewrite+0xf6>
      int n1 = n - i;
    800052e6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800052ea:	84be                	mv	s1,a5
    800052ec:	2781                	sext.w	a5,a5
    800052ee:	f8fb5ce3          	bge	s6,a5,80005286 <filewrite+0x84>
    800052f2:	84de                	mv	s1,s7
    800052f4:	bf49                	j	80005286 <filewrite+0x84>
    int i = 0;
    800052f6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800052f8:	013a1f63          	bne	s4,s3,80005316 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800052fc:	8552                	mv	a0,s4
    800052fe:	60a6                	ld	ra,72(sp)
    80005300:	6406                	ld	s0,64(sp)
    80005302:	74e2                	ld	s1,56(sp)
    80005304:	7942                	ld	s2,48(sp)
    80005306:	79a2                	ld	s3,40(sp)
    80005308:	7a02                	ld	s4,32(sp)
    8000530a:	6ae2                	ld	s5,24(sp)
    8000530c:	6b42                	ld	s6,16(sp)
    8000530e:	6ba2                	ld	s7,8(sp)
    80005310:	6c02                	ld	s8,0(sp)
    80005312:	6161                	addi	sp,sp,80
    80005314:	8082                	ret
    ret = (i == n ? n : -1);
    80005316:	5a7d                	li	s4,-1
    80005318:	b7d5                	j	800052fc <filewrite+0xfa>
    panic("filewrite");
    8000531a:	00003517          	auipc	a0,0x3
    8000531e:	65650513          	addi	a0,a0,1622 # 80008970 <syscalls+0x298>
    80005322:	ffffb097          	auipc	ra,0xffffb
    80005326:	222080e7          	jalr	546(ra) # 80000544 <panic>
    return -1;
    8000532a:	5a7d                	li	s4,-1
    8000532c:	bfc1                	j	800052fc <filewrite+0xfa>
      return -1;
    8000532e:	5a7d                	li	s4,-1
    80005330:	b7f1                	j	800052fc <filewrite+0xfa>
    80005332:	5a7d                	li	s4,-1
    80005334:	b7e1                	j	800052fc <filewrite+0xfa>

0000000080005336 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005336:	7179                	addi	sp,sp,-48
    80005338:	f406                	sd	ra,40(sp)
    8000533a:	f022                	sd	s0,32(sp)
    8000533c:	ec26                	sd	s1,24(sp)
    8000533e:	e84a                	sd	s2,16(sp)
    80005340:	e44e                	sd	s3,8(sp)
    80005342:	e052                	sd	s4,0(sp)
    80005344:	1800                	addi	s0,sp,48
    80005346:	84aa                	mv	s1,a0
    80005348:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000534a:	0005b023          	sd	zero,0(a1)
    8000534e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005352:	00000097          	auipc	ra,0x0
    80005356:	bf8080e7          	jalr	-1032(ra) # 80004f4a <filealloc>
    8000535a:	e088                	sd	a0,0(s1)
    8000535c:	c551                	beqz	a0,800053e8 <pipealloc+0xb2>
    8000535e:	00000097          	auipc	ra,0x0
    80005362:	bec080e7          	jalr	-1044(ra) # 80004f4a <filealloc>
    80005366:	00aa3023          	sd	a0,0(s4)
    8000536a:	c92d                	beqz	a0,800053dc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	890080e7          	jalr	-1904(ra) # 80000bfc <kalloc>
    80005374:	892a                	mv	s2,a0
    80005376:	c125                	beqz	a0,800053d6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005378:	4985                	li	s3,1
    8000537a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000537e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005382:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005386:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000538a:	00003597          	auipc	a1,0x3
    8000538e:	24658593          	addi	a1,a1,582 # 800085d0 <states.1862+0x238>
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	908080e7          	jalr	-1784(ra) # 80000c9a <initlock>
  (*f0)->type = FD_PIPE;
    8000539a:	609c                	ld	a5,0(s1)
    8000539c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800053a0:	609c                	ld	a5,0(s1)
    800053a2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800053a6:	609c                	ld	a5,0(s1)
    800053a8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800053ac:	609c                	ld	a5,0(s1)
    800053ae:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800053b2:	000a3783          	ld	a5,0(s4)
    800053b6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800053ba:	000a3783          	ld	a5,0(s4)
    800053be:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800053c2:	000a3783          	ld	a5,0(s4)
    800053c6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800053ca:	000a3783          	ld	a5,0(s4)
    800053ce:	0127b823          	sd	s2,16(a5)
  return 0;
    800053d2:	4501                	li	a0,0
    800053d4:	a025                	j	800053fc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800053d6:	6088                	ld	a0,0(s1)
    800053d8:	e501                	bnez	a0,800053e0 <pipealloc+0xaa>
    800053da:	a039                	j	800053e8 <pipealloc+0xb2>
    800053dc:	6088                	ld	a0,0(s1)
    800053de:	c51d                	beqz	a0,8000540c <pipealloc+0xd6>
    fileclose(*f0);
    800053e0:	00000097          	auipc	ra,0x0
    800053e4:	c26080e7          	jalr	-986(ra) # 80005006 <fileclose>
  if(*f1)
    800053e8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800053ec:	557d                	li	a0,-1
  if(*f1)
    800053ee:	c799                	beqz	a5,800053fc <pipealloc+0xc6>
    fileclose(*f1);
    800053f0:	853e                	mv	a0,a5
    800053f2:	00000097          	auipc	ra,0x0
    800053f6:	c14080e7          	jalr	-1004(ra) # 80005006 <fileclose>
  return -1;
    800053fa:	557d                	li	a0,-1
}
    800053fc:	70a2                	ld	ra,40(sp)
    800053fe:	7402                	ld	s0,32(sp)
    80005400:	64e2                	ld	s1,24(sp)
    80005402:	6942                	ld	s2,16(sp)
    80005404:	69a2                	ld	s3,8(sp)
    80005406:	6a02                	ld	s4,0(sp)
    80005408:	6145                	addi	sp,sp,48
    8000540a:	8082                	ret
  return -1;
    8000540c:	557d                	li	a0,-1
    8000540e:	b7fd                	j	800053fc <pipealloc+0xc6>

0000000080005410 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005410:	1101                	addi	sp,sp,-32
    80005412:	ec06                	sd	ra,24(sp)
    80005414:	e822                	sd	s0,16(sp)
    80005416:	e426                	sd	s1,8(sp)
    80005418:	e04a                	sd	s2,0(sp)
    8000541a:	1000                	addi	s0,sp,32
    8000541c:	84aa                	mv	s1,a0
    8000541e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005420:	ffffc097          	auipc	ra,0xffffc
    80005424:	90a080e7          	jalr	-1782(ra) # 80000d2a <acquire>
  if(writable){
    80005428:	02090d63          	beqz	s2,80005462 <pipeclose+0x52>
    pi->writeopen = 0;
    8000542c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005430:	21848513          	addi	a0,s1,536
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	544080e7          	jalr	1348(ra) # 80002978 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000543c:	2204b783          	ld	a5,544(s1)
    80005440:	eb95                	bnez	a5,80005474 <pipeclose+0x64>
    release(&pi->lock);
    80005442:	8526                	mv	a0,s1
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	99a080e7          	jalr	-1638(ra) # 80000dde <release>
    kfree((char*)pi);
    8000544c:	8526                	mv	a0,s1
    8000544e:	ffffb097          	auipc	ra,0xffffb
    80005452:	62c080e7          	jalr	1580(ra) # 80000a7a <kfree>
  } else
    release(&pi->lock);
}
    80005456:	60e2                	ld	ra,24(sp)
    80005458:	6442                	ld	s0,16(sp)
    8000545a:	64a2                	ld	s1,8(sp)
    8000545c:	6902                	ld	s2,0(sp)
    8000545e:	6105                	addi	sp,sp,32
    80005460:	8082                	ret
    pi->readopen = 0;
    80005462:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005466:	21c48513          	addi	a0,s1,540
    8000546a:	ffffd097          	auipc	ra,0xffffd
    8000546e:	50e080e7          	jalr	1294(ra) # 80002978 <wakeup>
    80005472:	b7e9                	j	8000543c <pipeclose+0x2c>
    release(&pi->lock);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffc097          	auipc	ra,0xffffc
    8000547a:	968080e7          	jalr	-1688(ra) # 80000dde <release>
}
    8000547e:	bfe1                	j	80005456 <pipeclose+0x46>

0000000080005480 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005480:	7159                	addi	sp,sp,-112
    80005482:	f486                	sd	ra,104(sp)
    80005484:	f0a2                	sd	s0,96(sp)
    80005486:	eca6                	sd	s1,88(sp)
    80005488:	e8ca                	sd	s2,80(sp)
    8000548a:	e4ce                	sd	s3,72(sp)
    8000548c:	e0d2                	sd	s4,64(sp)
    8000548e:	fc56                	sd	s5,56(sp)
    80005490:	f85a                	sd	s6,48(sp)
    80005492:	f45e                	sd	s7,40(sp)
    80005494:	f062                	sd	s8,32(sp)
    80005496:	ec66                	sd	s9,24(sp)
    80005498:	1880                	addi	s0,sp,112
    8000549a:	84aa                	mv	s1,a0
    8000549c:	8aae                	mv	s5,a1
    8000549e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800054a0:	ffffd097          	auipc	ra,0xffffd
    800054a4:	8be080e7          	jalr	-1858(ra) # 80001d5e <myproc>
    800054a8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffc097          	auipc	ra,0xffffc
    800054b0:	87e080e7          	jalr	-1922(ra) # 80000d2a <acquire>
  while(i < n){
    800054b4:	0d405463          	blez	s4,8000557c <pipewrite+0xfc>
    800054b8:	8ba6                	mv	s7,s1
  int i = 0;
    800054ba:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800054bc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800054be:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800054c2:	21c48c13          	addi	s8,s1,540
    800054c6:	a08d                	j	80005528 <pipewrite+0xa8>
      release(&pi->lock);
    800054c8:	8526                	mv	a0,s1
    800054ca:	ffffc097          	auipc	ra,0xffffc
    800054ce:	914080e7          	jalr	-1772(ra) # 80000dde <release>
      return -1;
    800054d2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800054d4:	854a                	mv	a0,s2
    800054d6:	70a6                	ld	ra,104(sp)
    800054d8:	7406                	ld	s0,96(sp)
    800054da:	64e6                	ld	s1,88(sp)
    800054dc:	6946                	ld	s2,80(sp)
    800054de:	69a6                	ld	s3,72(sp)
    800054e0:	6a06                	ld	s4,64(sp)
    800054e2:	7ae2                	ld	s5,56(sp)
    800054e4:	7b42                	ld	s6,48(sp)
    800054e6:	7ba2                	ld	s7,40(sp)
    800054e8:	7c02                	ld	s8,32(sp)
    800054ea:	6ce2                	ld	s9,24(sp)
    800054ec:	6165                	addi	sp,sp,112
    800054ee:	8082                	ret
      wakeup(&pi->nread);
    800054f0:	8566                	mv	a0,s9
    800054f2:	ffffd097          	auipc	ra,0xffffd
    800054f6:	486080e7          	jalr	1158(ra) # 80002978 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800054fa:	85de                	mv	a1,s7
    800054fc:	8562                	mv	a0,s8
    800054fe:	ffffd097          	auipc	ra,0xffffd
    80005502:	19e080e7          	jalr	414(ra) # 8000269c <sleep>
    80005506:	a839                	j	80005524 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005508:	21c4a783          	lw	a5,540(s1)
    8000550c:	0017871b          	addiw	a4,a5,1
    80005510:	20e4ae23          	sw	a4,540(s1)
    80005514:	1ff7f793          	andi	a5,a5,511
    80005518:	97a6                	add	a5,a5,s1
    8000551a:	f9f44703          	lbu	a4,-97(s0)
    8000551e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005522:	2905                	addiw	s2,s2,1
  while(i < n){
    80005524:	05495063          	bge	s2,s4,80005564 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80005528:	2204a783          	lw	a5,544(s1)
    8000552c:	dfd1                	beqz	a5,800054c8 <pipewrite+0x48>
    8000552e:	854e                	mv	a0,s3
    80005530:	ffffd097          	auipc	ra,0xffffd
    80005534:	698080e7          	jalr	1688(ra) # 80002bc8 <killed>
    80005538:	f941                	bnez	a0,800054c8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000553a:	2184a783          	lw	a5,536(s1)
    8000553e:	21c4a703          	lw	a4,540(s1)
    80005542:	2007879b          	addiw	a5,a5,512
    80005546:	faf705e3          	beq	a4,a5,800054f0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000554a:	4685                	li	a3,1
    8000554c:	01590633          	add	a2,s2,s5
    80005550:	f9f40593          	addi	a1,s0,-97
    80005554:	0509b503          	ld	a0,80(s3)
    80005558:	ffffc097          	auipc	ra,0xffffc
    8000555c:	332080e7          	jalr	818(ra) # 8000188a <copyin>
    80005560:	fb6514e3          	bne	a0,s6,80005508 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005564:	21848513          	addi	a0,s1,536
    80005568:	ffffd097          	auipc	ra,0xffffd
    8000556c:	410080e7          	jalr	1040(ra) # 80002978 <wakeup>
  release(&pi->lock);
    80005570:	8526                	mv	a0,s1
    80005572:	ffffc097          	auipc	ra,0xffffc
    80005576:	86c080e7          	jalr	-1940(ra) # 80000dde <release>
  return i;
    8000557a:	bfa9                	j	800054d4 <pipewrite+0x54>
  int i = 0;
    8000557c:	4901                	li	s2,0
    8000557e:	b7dd                	j	80005564 <pipewrite+0xe4>

0000000080005580 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005580:	715d                	addi	sp,sp,-80
    80005582:	e486                	sd	ra,72(sp)
    80005584:	e0a2                	sd	s0,64(sp)
    80005586:	fc26                	sd	s1,56(sp)
    80005588:	f84a                	sd	s2,48(sp)
    8000558a:	f44e                	sd	s3,40(sp)
    8000558c:	f052                	sd	s4,32(sp)
    8000558e:	ec56                	sd	s5,24(sp)
    80005590:	e85a                	sd	s6,16(sp)
    80005592:	0880                	addi	s0,sp,80
    80005594:	84aa                	mv	s1,a0
    80005596:	892e                	mv	s2,a1
    80005598:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000559a:	ffffc097          	auipc	ra,0xffffc
    8000559e:	7c4080e7          	jalr	1988(ra) # 80001d5e <myproc>
    800055a2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800055a4:	8b26                	mv	s6,s1
    800055a6:	8526                	mv	a0,s1
    800055a8:	ffffb097          	auipc	ra,0xffffb
    800055ac:	782080e7          	jalr	1922(ra) # 80000d2a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055b0:	2184a703          	lw	a4,536(s1)
    800055b4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055b8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055bc:	02f71763          	bne	a4,a5,800055ea <piperead+0x6a>
    800055c0:	2244a783          	lw	a5,548(s1)
    800055c4:	c39d                	beqz	a5,800055ea <piperead+0x6a>
    if(killed(pr)){
    800055c6:	8552                	mv	a0,s4
    800055c8:	ffffd097          	auipc	ra,0xffffd
    800055cc:	600080e7          	jalr	1536(ra) # 80002bc8 <killed>
    800055d0:	e941                	bnez	a0,80005660 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055d2:	85da                	mv	a1,s6
    800055d4:	854e                	mv	a0,s3
    800055d6:	ffffd097          	auipc	ra,0xffffd
    800055da:	0c6080e7          	jalr	198(ra) # 8000269c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055de:	2184a703          	lw	a4,536(s1)
    800055e2:	21c4a783          	lw	a5,540(s1)
    800055e6:	fcf70de3          	beq	a4,a5,800055c0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055ea:	09505263          	blez	s5,8000566e <piperead+0xee>
    800055ee:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055f0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800055f2:	2184a783          	lw	a5,536(s1)
    800055f6:	21c4a703          	lw	a4,540(s1)
    800055fa:	02f70d63          	beq	a4,a5,80005634 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800055fe:	0017871b          	addiw	a4,a5,1
    80005602:	20e4ac23          	sw	a4,536(s1)
    80005606:	1ff7f793          	andi	a5,a5,511
    8000560a:	97a6                	add	a5,a5,s1
    8000560c:	0187c783          	lbu	a5,24(a5)
    80005610:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005614:	4685                	li	a3,1
    80005616:	fbf40613          	addi	a2,s0,-65
    8000561a:	85ca                	mv	a1,s2
    8000561c:	050a3503          	ld	a0,80(s4)
    80005620:	ffffc097          	auipc	ra,0xffffc
    80005624:	18a080e7          	jalr	394(ra) # 800017aa <copyout>
    80005628:	01650663          	beq	a0,s6,80005634 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000562c:	2985                	addiw	s3,s3,1
    8000562e:	0905                	addi	s2,s2,1
    80005630:	fd3a91e3          	bne	s5,s3,800055f2 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005634:	21c48513          	addi	a0,s1,540
    80005638:	ffffd097          	auipc	ra,0xffffd
    8000563c:	340080e7          	jalr	832(ra) # 80002978 <wakeup>
  release(&pi->lock);
    80005640:	8526                	mv	a0,s1
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	79c080e7          	jalr	1948(ra) # 80000dde <release>
  return i;
}
    8000564a:	854e                	mv	a0,s3
    8000564c:	60a6                	ld	ra,72(sp)
    8000564e:	6406                	ld	s0,64(sp)
    80005650:	74e2                	ld	s1,56(sp)
    80005652:	7942                	ld	s2,48(sp)
    80005654:	79a2                	ld	s3,40(sp)
    80005656:	7a02                	ld	s4,32(sp)
    80005658:	6ae2                	ld	s5,24(sp)
    8000565a:	6b42                	ld	s6,16(sp)
    8000565c:	6161                	addi	sp,sp,80
    8000565e:	8082                	ret
      release(&pi->lock);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	77c080e7          	jalr	1916(ra) # 80000dde <release>
      return -1;
    8000566a:	59fd                	li	s3,-1
    8000566c:	bff9                	j	8000564a <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000566e:	4981                	li	s3,0
    80005670:	b7d1                	j	80005634 <piperead+0xb4>

0000000080005672 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005672:	1141                	addi	sp,sp,-16
    80005674:	e422                	sd	s0,8(sp)
    80005676:	0800                	addi	s0,sp,16
    80005678:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000567a:	8905                	andi	a0,a0,1
    8000567c:	c111                	beqz	a0,80005680 <flags2perm+0xe>
      perm = PTE_X;
    8000567e:	4521                	li	a0,8
    if(flags & 0x2)
    80005680:	8b89                	andi	a5,a5,2
    80005682:	c399                	beqz	a5,80005688 <flags2perm+0x16>
      perm |= PTE_W;
    80005684:	00456513          	ori	a0,a0,4
    return perm;
}
    80005688:	6422                	ld	s0,8(sp)
    8000568a:	0141                	addi	sp,sp,16
    8000568c:	8082                	ret

000000008000568e <exec>:

int
exec(char *path, char **argv)
{
    8000568e:	df010113          	addi	sp,sp,-528
    80005692:	20113423          	sd	ra,520(sp)
    80005696:	20813023          	sd	s0,512(sp)
    8000569a:	ffa6                	sd	s1,504(sp)
    8000569c:	fbca                	sd	s2,496(sp)
    8000569e:	f7ce                	sd	s3,488(sp)
    800056a0:	f3d2                	sd	s4,480(sp)
    800056a2:	efd6                	sd	s5,472(sp)
    800056a4:	ebda                	sd	s6,464(sp)
    800056a6:	e7de                	sd	s7,456(sp)
    800056a8:	e3e2                	sd	s8,448(sp)
    800056aa:	ff66                	sd	s9,440(sp)
    800056ac:	fb6a                	sd	s10,432(sp)
    800056ae:	f76e                	sd	s11,424(sp)
    800056b0:	0c00                	addi	s0,sp,528
    800056b2:	84aa                	mv	s1,a0
    800056b4:	dea43c23          	sd	a0,-520(s0)
    800056b8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800056bc:	ffffc097          	auipc	ra,0xffffc
    800056c0:	6a2080e7          	jalr	1698(ra) # 80001d5e <myproc>
    800056c4:	892a                	mv	s2,a0

  begin_op();
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	474080e7          	jalr	1140(ra) # 80004b3a <begin_op>

  if((ip = namei(path)) == 0){
    800056ce:	8526                	mv	a0,s1
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	24e080e7          	jalr	590(ra) # 8000491e <namei>
    800056d8:	c92d                	beqz	a0,8000574a <exec+0xbc>
    800056da:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	a9c080e7          	jalr	-1380(ra) # 80004178 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800056e4:	04000713          	li	a4,64
    800056e8:	4681                	li	a3,0
    800056ea:	e5040613          	addi	a2,s0,-432
    800056ee:	4581                	li	a1,0
    800056f0:	8526                	mv	a0,s1
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	d3a080e7          	jalr	-710(ra) # 8000442c <readi>
    800056fa:	04000793          	li	a5,64
    800056fe:	00f51a63          	bne	a0,a5,80005712 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005702:	e5042703          	lw	a4,-432(s0)
    80005706:	464c47b7          	lui	a5,0x464c4
    8000570a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000570e:	04f70463          	beq	a4,a5,80005756 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005712:	8526                	mv	a0,s1
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	cc6080e7          	jalr	-826(ra) # 800043da <iunlockput>
    end_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	49e080e7          	jalr	1182(ra) # 80004bba <end_op>
  }
  return -1;
    80005724:	557d                	li	a0,-1
}
    80005726:	20813083          	ld	ra,520(sp)
    8000572a:	20013403          	ld	s0,512(sp)
    8000572e:	74fe                	ld	s1,504(sp)
    80005730:	795e                	ld	s2,496(sp)
    80005732:	79be                	ld	s3,488(sp)
    80005734:	7a1e                	ld	s4,480(sp)
    80005736:	6afe                	ld	s5,472(sp)
    80005738:	6b5e                	ld	s6,464(sp)
    8000573a:	6bbe                	ld	s7,456(sp)
    8000573c:	6c1e                	ld	s8,448(sp)
    8000573e:	7cfa                	ld	s9,440(sp)
    80005740:	7d5a                	ld	s10,432(sp)
    80005742:	7dba                	ld	s11,424(sp)
    80005744:	21010113          	addi	sp,sp,528
    80005748:	8082                	ret
    end_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	470080e7          	jalr	1136(ra) # 80004bba <end_op>
    return -1;
    80005752:	557d                	li	a0,-1
    80005754:	bfc9                	j	80005726 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005756:	854a                	mv	a0,s2
    80005758:	ffffc097          	auipc	ra,0xffffc
    8000575c:	7f0080e7          	jalr	2032(ra) # 80001f48 <proc_pagetable>
    80005760:	8baa                	mv	s7,a0
    80005762:	d945                	beqz	a0,80005712 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005764:	e7042983          	lw	s3,-400(s0)
    80005768:	e8845783          	lhu	a5,-376(s0)
    8000576c:	c7ad                	beqz	a5,800057d6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000576e:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005770:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005772:	6c85                	lui	s9,0x1
    80005774:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005778:	def43823          	sd	a5,-528(s0)
    8000577c:	ac0d                	j	800059ae <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000577e:	00003517          	auipc	a0,0x3
    80005782:	20250513          	addi	a0,a0,514 # 80008980 <syscalls+0x2a8>
    80005786:	ffffb097          	auipc	ra,0xffffb
    8000578a:	dbe080e7          	jalr	-578(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000578e:	8756                	mv	a4,s5
    80005790:	012d86bb          	addw	a3,s11,s2
    80005794:	4581                	li	a1,0
    80005796:	8526                	mv	a0,s1
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	c94080e7          	jalr	-876(ra) # 8000442c <readi>
    800057a0:	2501                	sext.w	a0,a0
    800057a2:	1aaa9a63          	bne	s5,a0,80005956 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    800057a6:	6785                	lui	a5,0x1
    800057a8:	0127893b          	addw	s2,a5,s2
    800057ac:	77fd                	lui	a5,0xfffff
    800057ae:	01478a3b          	addw	s4,a5,s4
    800057b2:	1f897563          	bgeu	s2,s8,8000599c <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    800057b6:	02091593          	slli	a1,s2,0x20
    800057ba:	9181                	srli	a1,a1,0x20
    800057bc:	95ea                	add	a1,a1,s10
    800057be:	855e                	mv	a0,s7
    800057c0:	ffffc097          	auipc	ra,0xffffc
    800057c4:	9f8080e7          	jalr	-1544(ra) # 800011b8 <walkaddr>
    800057c8:	862a                	mv	a2,a0
    if(pa == 0)
    800057ca:	d955                	beqz	a0,8000577e <exec+0xf0>
      n = PGSIZE;
    800057cc:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800057ce:	fd9a70e3          	bgeu	s4,s9,8000578e <exec+0x100>
      n = sz - i;
    800057d2:	8ad2                	mv	s5,s4
    800057d4:	bf6d                	j	8000578e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800057d6:	4a01                	li	s4,0
  iunlockput(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	c00080e7          	jalr	-1024(ra) # 800043da <iunlockput>
  end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	3d8080e7          	jalr	984(ra) # 80004bba <end_op>
  p = myproc();
    800057ea:	ffffc097          	auipc	ra,0xffffc
    800057ee:	574080e7          	jalr	1396(ra) # 80001d5e <myproc>
    800057f2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800057f4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800057f8:	6785                	lui	a5,0x1
    800057fa:	17fd                	addi	a5,a5,-1
    800057fc:	9a3e                	add	s4,s4,a5
    800057fe:	757d                	lui	a0,0xfffff
    80005800:	00aa77b3          	and	a5,s4,a0
    80005804:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005808:	4691                	li	a3,4
    8000580a:	6609                	lui	a2,0x2
    8000580c:	963e                	add	a2,a2,a5
    8000580e:	85be                	mv	a1,a5
    80005810:	855e                	mv	a0,s7
    80005812:	ffffc097          	auipc	ra,0xffffc
    80005816:	d5a080e7          	jalr	-678(ra) # 8000156c <uvmalloc>
    8000581a:	8b2a                	mv	s6,a0
  ip = 0;
    8000581c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000581e:	12050c63          	beqz	a0,80005956 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005822:	75f9                	lui	a1,0xffffe
    80005824:	95aa                	add	a1,a1,a0
    80005826:	855e                	mv	a0,s7
    80005828:	ffffc097          	auipc	ra,0xffffc
    8000582c:	f50080e7          	jalr	-176(ra) # 80001778 <uvmclear>
  stackbase = sp - PGSIZE;
    80005830:	7c7d                	lui	s8,0xfffff
    80005832:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005834:	e0043783          	ld	a5,-512(s0)
    80005838:	6388                	ld	a0,0(a5)
    8000583a:	c535                	beqz	a0,800058a6 <exec+0x218>
    8000583c:	e9040993          	addi	s3,s0,-368
    80005840:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005844:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005846:	ffffb097          	auipc	ra,0xffffb
    8000584a:	764080e7          	jalr	1892(ra) # 80000faa <strlen>
    8000584e:	2505                	addiw	a0,a0,1
    80005850:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005854:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005858:	13896663          	bltu	s2,s8,80005984 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000585c:	e0043d83          	ld	s11,-512(s0)
    80005860:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005864:	8552                	mv	a0,s4
    80005866:	ffffb097          	auipc	ra,0xffffb
    8000586a:	744080e7          	jalr	1860(ra) # 80000faa <strlen>
    8000586e:	0015069b          	addiw	a3,a0,1
    80005872:	8652                	mv	a2,s4
    80005874:	85ca                	mv	a1,s2
    80005876:	855e                	mv	a0,s7
    80005878:	ffffc097          	auipc	ra,0xffffc
    8000587c:	f32080e7          	jalr	-206(ra) # 800017aa <copyout>
    80005880:	10054663          	bltz	a0,8000598c <exec+0x2fe>
    ustack[argc] = sp;
    80005884:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005888:	0485                	addi	s1,s1,1
    8000588a:	008d8793          	addi	a5,s11,8
    8000588e:	e0f43023          	sd	a5,-512(s0)
    80005892:	008db503          	ld	a0,8(s11)
    80005896:	c911                	beqz	a0,800058aa <exec+0x21c>
    if(argc >= MAXARG)
    80005898:	09a1                	addi	s3,s3,8
    8000589a:	fb3c96e3          	bne	s9,s3,80005846 <exec+0x1b8>
  sz = sz1;
    8000589e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800058a2:	4481                	li	s1,0
    800058a4:	a84d                	j	80005956 <exec+0x2c8>
  sp = sz;
    800058a6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800058a8:	4481                	li	s1,0
  ustack[argc] = 0;
    800058aa:	00349793          	slli	a5,s1,0x3
    800058ae:	f9040713          	addi	a4,s0,-112
    800058b2:	97ba                	add	a5,a5,a4
    800058b4:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800058b8:	00148693          	addi	a3,s1,1
    800058bc:	068e                	slli	a3,a3,0x3
    800058be:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800058c2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800058c6:	01897663          	bgeu	s2,s8,800058d2 <exec+0x244>
  sz = sz1;
    800058ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800058ce:	4481                	li	s1,0
    800058d0:	a059                	j	80005956 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800058d2:	e9040613          	addi	a2,s0,-368
    800058d6:	85ca                	mv	a1,s2
    800058d8:	855e                	mv	a0,s7
    800058da:	ffffc097          	auipc	ra,0xffffc
    800058de:	ed0080e7          	jalr	-304(ra) # 800017aa <copyout>
    800058e2:	0a054963          	bltz	a0,80005994 <exec+0x306>
  p->trapframe->a1 = sp;
    800058e6:	058ab783          	ld	a5,88(s5)
    800058ea:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800058ee:	df843783          	ld	a5,-520(s0)
    800058f2:	0007c703          	lbu	a4,0(a5)
    800058f6:	cf11                	beqz	a4,80005912 <exec+0x284>
    800058f8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800058fa:	02f00693          	li	a3,47
    800058fe:	a039                	j	8000590c <exec+0x27e>
      last = s+1;
    80005900:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005904:	0785                	addi	a5,a5,1
    80005906:	fff7c703          	lbu	a4,-1(a5)
    8000590a:	c701                	beqz	a4,80005912 <exec+0x284>
    if(*s == '/')
    8000590c:	fed71ce3          	bne	a4,a3,80005904 <exec+0x276>
    80005910:	bfc5                	j	80005900 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005912:	4641                	li	a2,16
    80005914:	df843583          	ld	a1,-520(s0)
    80005918:	158a8513          	addi	a0,s5,344
    8000591c:	ffffb097          	auipc	ra,0xffffb
    80005920:	65c080e7          	jalr	1628(ra) # 80000f78 <safestrcpy>
  oldpagetable = p->pagetable;
    80005924:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005928:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000592c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005930:	058ab783          	ld	a5,88(s5)
    80005934:	e6843703          	ld	a4,-408(s0)
    80005938:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000593a:	058ab783          	ld	a5,88(s5)
    8000593e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005942:	85ea                	mv	a1,s10
    80005944:	ffffc097          	auipc	ra,0xffffc
    80005948:	6a0080e7          	jalr	1696(ra) # 80001fe4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000594c:	0004851b          	sext.w	a0,s1
    80005950:	bbd9                	j	80005726 <exec+0x98>
    80005952:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005956:	e0843583          	ld	a1,-504(s0)
    8000595a:	855e                	mv	a0,s7
    8000595c:	ffffc097          	auipc	ra,0xffffc
    80005960:	688080e7          	jalr	1672(ra) # 80001fe4 <proc_freepagetable>
  if(ip){
    80005964:	da0497e3          	bnez	s1,80005712 <exec+0x84>
  return -1;
    80005968:	557d                	li	a0,-1
    8000596a:	bb75                	j	80005726 <exec+0x98>
    8000596c:	e1443423          	sd	s4,-504(s0)
    80005970:	b7dd                	j	80005956 <exec+0x2c8>
    80005972:	e1443423          	sd	s4,-504(s0)
    80005976:	b7c5                	j	80005956 <exec+0x2c8>
    80005978:	e1443423          	sd	s4,-504(s0)
    8000597c:	bfe9                	j	80005956 <exec+0x2c8>
    8000597e:	e1443423          	sd	s4,-504(s0)
    80005982:	bfd1                	j	80005956 <exec+0x2c8>
  sz = sz1;
    80005984:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005988:	4481                	li	s1,0
    8000598a:	b7f1                	j	80005956 <exec+0x2c8>
  sz = sz1;
    8000598c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005990:	4481                	li	s1,0
    80005992:	b7d1                	j	80005956 <exec+0x2c8>
  sz = sz1;
    80005994:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005998:	4481                	li	s1,0
    8000599a:	bf75                	j	80005956 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000599c:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059a0:	2b05                	addiw	s6,s6,1
    800059a2:	0389899b          	addiw	s3,s3,56
    800059a6:	e8845783          	lhu	a5,-376(s0)
    800059aa:	e2fb57e3          	bge	s6,a5,800057d8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800059ae:	2981                	sext.w	s3,s3
    800059b0:	03800713          	li	a4,56
    800059b4:	86ce                	mv	a3,s3
    800059b6:	e1840613          	addi	a2,s0,-488
    800059ba:	4581                	li	a1,0
    800059bc:	8526                	mv	a0,s1
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	a6e080e7          	jalr	-1426(ra) # 8000442c <readi>
    800059c6:	03800793          	li	a5,56
    800059ca:	f8f514e3          	bne	a0,a5,80005952 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800059ce:	e1842783          	lw	a5,-488(s0)
    800059d2:	4705                	li	a4,1
    800059d4:	fce796e3          	bne	a5,a4,800059a0 <exec+0x312>
    if(ph.memsz < ph.filesz)
    800059d8:	e4043903          	ld	s2,-448(s0)
    800059dc:	e3843783          	ld	a5,-456(s0)
    800059e0:	f8f966e3          	bltu	s2,a5,8000596c <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800059e4:	e2843783          	ld	a5,-472(s0)
    800059e8:	993e                	add	s2,s2,a5
    800059ea:	f8f964e3          	bltu	s2,a5,80005972 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800059ee:	df043703          	ld	a4,-528(s0)
    800059f2:	8ff9                	and	a5,a5,a4
    800059f4:	f3d1                	bnez	a5,80005978 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800059f6:	e1c42503          	lw	a0,-484(s0)
    800059fa:	00000097          	auipc	ra,0x0
    800059fe:	c78080e7          	jalr	-904(ra) # 80005672 <flags2perm>
    80005a02:	86aa                	mv	a3,a0
    80005a04:	864a                	mv	a2,s2
    80005a06:	85d2                	mv	a1,s4
    80005a08:	855e                	mv	a0,s7
    80005a0a:	ffffc097          	auipc	ra,0xffffc
    80005a0e:	b62080e7          	jalr	-1182(ra) # 8000156c <uvmalloc>
    80005a12:	e0a43423          	sd	a0,-504(s0)
    80005a16:	d525                	beqz	a0,8000597e <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005a18:	e2843d03          	ld	s10,-472(s0)
    80005a1c:	e2042d83          	lw	s11,-480(s0)
    80005a20:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005a24:	f60c0ce3          	beqz	s8,8000599c <exec+0x30e>
    80005a28:	8a62                	mv	s4,s8
    80005a2a:	4901                	li	s2,0
    80005a2c:	b369                	j	800057b6 <exec+0x128>

0000000080005a2e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005a2e:	7179                	addi	sp,sp,-48
    80005a30:	f406                	sd	ra,40(sp)
    80005a32:	f022                	sd	s0,32(sp)
    80005a34:	ec26                	sd	s1,24(sp)
    80005a36:	e84a                	sd	s2,16(sp)
    80005a38:	1800                	addi	s0,sp,48
    80005a3a:	892e                	mv	s2,a1
    80005a3c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005a3e:	fdc40593          	addi	a1,s0,-36
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	92e080e7          	jalr	-1746(ra) # 80003370 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005a4a:	fdc42703          	lw	a4,-36(s0)
    80005a4e:	47bd                	li	a5,15
    80005a50:	02e7eb63          	bltu	a5,a4,80005a86 <argfd+0x58>
    80005a54:	ffffc097          	auipc	ra,0xffffc
    80005a58:	30a080e7          	jalr	778(ra) # 80001d5e <myproc>
    80005a5c:	fdc42703          	lw	a4,-36(s0)
    80005a60:	01a70793          	addi	a5,a4,26
    80005a64:	078e                	slli	a5,a5,0x3
    80005a66:	953e                	add	a0,a0,a5
    80005a68:	611c                	ld	a5,0(a0)
    80005a6a:	c385                	beqz	a5,80005a8a <argfd+0x5c>
    return -1;
  if(pfd)
    80005a6c:	00090463          	beqz	s2,80005a74 <argfd+0x46>
    *pfd = fd;
    80005a70:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005a74:	4501                	li	a0,0
  if(pf)
    80005a76:	c091                	beqz	s1,80005a7a <argfd+0x4c>
    *pf = f;
    80005a78:	e09c                	sd	a5,0(s1)
}
    80005a7a:	70a2                	ld	ra,40(sp)
    80005a7c:	7402                	ld	s0,32(sp)
    80005a7e:	64e2                	ld	s1,24(sp)
    80005a80:	6942                	ld	s2,16(sp)
    80005a82:	6145                	addi	sp,sp,48
    80005a84:	8082                	ret
    return -1;
    80005a86:	557d                	li	a0,-1
    80005a88:	bfcd                	j	80005a7a <argfd+0x4c>
    80005a8a:	557d                	li	a0,-1
    80005a8c:	b7fd                	j	80005a7a <argfd+0x4c>

0000000080005a8e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005a8e:	1101                	addi	sp,sp,-32
    80005a90:	ec06                	sd	ra,24(sp)
    80005a92:	e822                	sd	s0,16(sp)
    80005a94:	e426                	sd	s1,8(sp)
    80005a96:	1000                	addi	s0,sp,32
    80005a98:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005a9a:	ffffc097          	auipc	ra,0xffffc
    80005a9e:	2c4080e7          	jalr	708(ra) # 80001d5e <myproc>
    80005aa2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005aa4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7fdba410>
    80005aa8:	4501                	li	a0,0
    80005aaa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005aac:	6398                	ld	a4,0(a5)
    80005aae:	cb19                	beqz	a4,80005ac4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005ab0:	2505                	addiw	a0,a0,1
    80005ab2:	07a1                	addi	a5,a5,8
    80005ab4:	fed51ce3          	bne	a0,a3,80005aac <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005ab8:	557d                	li	a0,-1
}
    80005aba:	60e2                	ld	ra,24(sp)
    80005abc:	6442                	ld	s0,16(sp)
    80005abe:	64a2                	ld	s1,8(sp)
    80005ac0:	6105                	addi	sp,sp,32
    80005ac2:	8082                	ret
      p->ofile[fd] = f;
    80005ac4:	01a50793          	addi	a5,a0,26
    80005ac8:	078e                	slli	a5,a5,0x3
    80005aca:	963e                	add	a2,a2,a5
    80005acc:	e204                	sd	s1,0(a2)
      return fd;
    80005ace:	b7f5                	j	80005aba <fdalloc+0x2c>

0000000080005ad0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005ad0:	715d                	addi	sp,sp,-80
    80005ad2:	e486                	sd	ra,72(sp)
    80005ad4:	e0a2                	sd	s0,64(sp)
    80005ad6:	fc26                	sd	s1,56(sp)
    80005ad8:	f84a                	sd	s2,48(sp)
    80005ada:	f44e                	sd	s3,40(sp)
    80005adc:	f052                	sd	s4,32(sp)
    80005ade:	ec56                	sd	s5,24(sp)
    80005ae0:	e85a                	sd	s6,16(sp)
    80005ae2:	0880                	addi	s0,sp,80
    80005ae4:	8b2e                	mv	s6,a1
    80005ae6:	89b2                	mv	s3,a2
    80005ae8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005aea:	fb040593          	addi	a1,s0,-80
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	e4e080e7          	jalr	-434(ra) # 8000493c <nameiparent>
    80005af6:	84aa                	mv	s1,a0
    80005af8:	16050063          	beqz	a0,80005c58 <create+0x188>
    return 0;

  ilock(dp);
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	67c080e7          	jalr	1660(ra) # 80004178 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005b04:	4601                	li	a2,0
    80005b06:	fb040593          	addi	a1,s0,-80
    80005b0a:	8526                	mv	a0,s1
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	b50080e7          	jalr	-1200(ra) # 8000465c <dirlookup>
    80005b14:	8aaa                	mv	s5,a0
    80005b16:	c931                	beqz	a0,80005b6a <create+0x9a>
    iunlockput(dp);
    80005b18:	8526                	mv	a0,s1
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	8c0080e7          	jalr	-1856(ra) # 800043da <iunlockput>
    ilock(ip);
    80005b22:	8556                	mv	a0,s5
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	654080e7          	jalr	1620(ra) # 80004178 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005b2c:	000b059b          	sext.w	a1,s6
    80005b30:	4789                	li	a5,2
    80005b32:	02f59563          	bne	a1,a5,80005b5c <create+0x8c>
    80005b36:	044ad783          	lhu	a5,68(s5)
    80005b3a:	37f9                	addiw	a5,a5,-2
    80005b3c:	17c2                	slli	a5,a5,0x30
    80005b3e:	93c1                	srli	a5,a5,0x30
    80005b40:	4705                	li	a4,1
    80005b42:	00f76d63          	bltu	a4,a5,80005b5c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005b46:	8556                	mv	a0,s5
    80005b48:	60a6                	ld	ra,72(sp)
    80005b4a:	6406                	ld	s0,64(sp)
    80005b4c:	74e2                	ld	s1,56(sp)
    80005b4e:	7942                	ld	s2,48(sp)
    80005b50:	79a2                	ld	s3,40(sp)
    80005b52:	7a02                	ld	s4,32(sp)
    80005b54:	6ae2                	ld	s5,24(sp)
    80005b56:	6b42                	ld	s6,16(sp)
    80005b58:	6161                	addi	sp,sp,80
    80005b5a:	8082                	ret
    iunlockput(ip);
    80005b5c:	8556                	mv	a0,s5
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	87c080e7          	jalr	-1924(ra) # 800043da <iunlockput>
    return 0;
    80005b66:	4a81                	li	s5,0
    80005b68:	bff9                	j	80005b46 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005b6a:	85da                	mv	a1,s6
    80005b6c:	4088                	lw	a0,0(s1)
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	46e080e7          	jalr	1134(ra) # 80003fdc <ialloc>
    80005b76:	8a2a                	mv	s4,a0
    80005b78:	c921                	beqz	a0,80005bc8 <create+0xf8>
  ilock(ip);
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	5fe080e7          	jalr	1534(ra) # 80004178 <ilock>
  ip->major = major;
    80005b82:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005b86:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005b8a:	4785                	li	a5,1
    80005b8c:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005b90:	8552                	mv	a0,s4
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	51c080e7          	jalr	1308(ra) # 800040ae <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005b9a:	000b059b          	sext.w	a1,s6
    80005b9e:	4785                	li	a5,1
    80005ba0:	02f58b63          	beq	a1,a5,80005bd6 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ba4:	004a2603          	lw	a2,4(s4)
    80005ba8:	fb040593          	addi	a1,s0,-80
    80005bac:	8526                	mv	a0,s1
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	cbe080e7          	jalr	-834(ra) # 8000486c <dirlink>
    80005bb6:	06054f63          	bltz	a0,80005c34 <create+0x164>
  iunlockput(dp);
    80005bba:	8526                	mv	a0,s1
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	81e080e7          	jalr	-2018(ra) # 800043da <iunlockput>
  return ip;
    80005bc4:	8ad2                	mv	s5,s4
    80005bc6:	b741                	j	80005b46 <create+0x76>
    iunlockput(dp);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	810080e7          	jalr	-2032(ra) # 800043da <iunlockput>
    return 0;
    80005bd2:	8ad2                	mv	s5,s4
    80005bd4:	bf8d                	j	80005b46 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005bd6:	004a2603          	lw	a2,4(s4)
    80005bda:	00003597          	auipc	a1,0x3
    80005bde:	dc658593          	addi	a1,a1,-570 # 800089a0 <syscalls+0x2c8>
    80005be2:	8552                	mv	a0,s4
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	c88080e7          	jalr	-888(ra) # 8000486c <dirlink>
    80005bec:	04054463          	bltz	a0,80005c34 <create+0x164>
    80005bf0:	40d0                	lw	a2,4(s1)
    80005bf2:	00003597          	auipc	a1,0x3
    80005bf6:	db658593          	addi	a1,a1,-586 # 800089a8 <syscalls+0x2d0>
    80005bfa:	8552                	mv	a0,s4
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	c70080e7          	jalr	-912(ra) # 8000486c <dirlink>
    80005c04:	02054863          	bltz	a0,80005c34 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005c08:	004a2603          	lw	a2,4(s4)
    80005c0c:	fb040593          	addi	a1,s0,-80
    80005c10:	8526                	mv	a0,s1
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	c5a080e7          	jalr	-934(ra) # 8000486c <dirlink>
    80005c1a:	00054d63          	bltz	a0,80005c34 <create+0x164>
    dp->nlink++;  // for ".."
    80005c1e:	04a4d783          	lhu	a5,74(s1)
    80005c22:	2785                	addiw	a5,a5,1
    80005c24:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	484080e7          	jalr	1156(ra) # 800040ae <iupdate>
    80005c32:	b761                	j	80005bba <create+0xea>
  ip->nlink = 0;
    80005c34:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005c38:	8552                	mv	a0,s4
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	474080e7          	jalr	1140(ra) # 800040ae <iupdate>
  iunlockput(ip);
    80005c42:	8552                	mv	a0,s4
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	796080e7          	jalr	1942(ra) # 800043da <iunlockput>
  iunlockput(dp);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	78c080e7          	jalr	1932(ra) # 800043da <iunlockput>
  return 0;
    80005c56:	bdc5                	j	80005b46 <create+0x76>
    return 0;
    80005c58:	8aaa                	mv	s5,a0
    80005c5a:	b5f5                	j	80005b46 <create+0x76>

0000000080005c5c <sys_dup>:
{
    80005c5c:	7179                	addi	sp,sp,-48
    80005c5e:	f406                	sd	ra,40(sp)
    80005c60:	f022                	sd	s0,32(sp)
    80005c62:	ec26                	sd	s1,24(sp)
    80005c64:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005c66:	fd840613          	addi	a2,s0,-40
    80005c6a:	4581                	li	a1,0
    80005c6c:	4501                	li	a0,0
    80005c6e:	00000097          	auipc	ra,0x0
    80005c72:	dc0080e7          	jalr	-576(ra) # 80005a2e <argfd>
    return -1;
    80005c76:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005c78:	02054363          	bltz	a0,80005c9e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005c7c:	fd843503          	ld	a0,-40(s0)
    80005c80:	00000097          	auipc	ra,0x0
    80005c84:	e0e080e7          	jalr	-498(ra) # 80005a8e <fdalloc>
    80005c88:	84aa                	mv	s1,a0
    return -1;
    80005c8a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005c8c:	00054963          	bltz	a0,80005c9e <sys_dup+0x42>
  filedup(f);
    80005c90:	fd843503          	ld	a0,-40(s0)
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	320080e7          	jalr	800(ra) # 80004fb4 <filedup>
  return fd;
    80005c9c:	87a6                	mv	a5,s1
}
    80005c9e:	853e                	mv	a0,a5
    80005ca0:	70a2                	ld	ra,40(sp)
    80005ca2:	7402                	ld	s0,32(sp)
    80005ca4:	64e2                	ld	s1,24(sp)
    80005ca6:	6145                	addi	sp,sp,48
    80005ca8:	8082                	ret

0000000080005caa <sys_read>:
{
    80005caa:	7179                	addi	sp,sp,-48
    80005cac:	f406                	sd	ra,40(sp)
    80005cae:	f022                	sd	s0,32(sp)
    80005cb0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005cb2:	fd840593          	addi	a1,s0,-40
    80005cb6:	4505                	li	a0,1
    80005cb8:	ffffd097          	auipc	ra,0xffffd
    80005cbc:	6d8080e7          	jalr	1752(ra) # 80003390 <argaddr>
  argint(2, &n);
    80005cc0:	fe440593          	addi	a1,s0,-28
    80005cc4:	4509                	li	a0,2
    80005cc6:	ffffd097          	auipc	ra,0xffffd
    80005cca:	6aa080e7          	jalr	1706(ra) # 80003370 <argint>
  if(argfd(0, 0, &f) < 0)
    80005cce:	fe840613          	addi	a2,s0,-24
    80005cd2:	4581                	li	a1,0
    80005cd4:	4501                	li	a0,0
    80005cd6:	00000097          	auipc	ra,0x0
    80005cda:	d58080e7          	jalr	-680(ra) # 80005a2e <argfd>
    80005cde:	87aa                	mv	a5,a0
    return -1;
    80005ce0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ce2:	0007cc63          	bltz	a5,80005cfa <sys_read+0x50>
  return fileread(f, p, n);
    80005ce6:	fe442603          	lw	a2,-28(s0)
    80005cea:	fd843583          	ld	a1,-40(s0)
    80005cee:	fe843503          	ld	a0,-24(s0)
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	44e080e7          	jalr	1102(ra) # 80005140 <fileread>
}
    80005cfa:	70a2                	ld	ra,40(sp)
    80005cfc:	7402                	ld	s0,32(sp)
    80005cfe:	6145                	addi	sp,sp,48
    80005d00:	8082                	ret

0000000080005d02 <sys_write>:
{
    80005d02:	7179                	addi	sp,sp,-48
    80005d04:	f406                	sd	ra,40(sp)
    80005d06:	f022                	sd	s0,32(sp)
    80005d08:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005d0a:	fd840593          	addi	a1,s0,-40
    80005d0e:	4505                	li	a0,1
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	680080e7          	jalr	1664(ra) # 80003390 <argaddr>
  argint(2, &n);
    80005d18:	fe440593          	addi	a1,s0,-28
    80005d1c:	4509                	li	a0,2
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	652080e7          	jalr	1618(ra) # 80003370 <argint>
  if(argfd(0, 0, &f) < 0)
    80005d26:	fe840613          	addi	a2,s0,-24
    80005d2a:	4581                	li	a1,0
    80005d2c:	4501                	li	a0,0
    80005d2e:	00000097          	auipc	ra,0x0
    80005d32:	d00080e7          	jalr	-768(ra) # 80005a2e <argfd>
    80005d36:	87aa                	mv	a5,a0
    return -1;
    80005d38:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d3a:	0007cc63          	bltz	a5,80005d52 <sys_write+0x50>
  return filewrite(f, p, n);
    80005d3e:	fe442603          	lw	a2,-28(s0)
    80005d42:	fd843583          	ld	a1,-40(s0)
    80005d46:	fe843503          	ld	a0,-24(s0)
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	4b8080e7          	jalr	1208(ra) # 80005202 <filewrite>
}
    80005d52:	70a2                	ld	ra,40(sp)
    80005d54:	7402                	ld	s0,32(sp)
    80005d56:	6145                	addi	sp,sp,48
    80005d58:	8082                	ret

0000000080005d5a <sys_close>:
{
    80005d5a:	1101                	addi	sp,sp,-32
    80005d5c:	ec06                	sd	ra,24(sp)
    80005d5e:	e822                	sd	s0,16(sp)
    80005d60:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005d62:	fe040613          	addi	a2,s0,-32
    80005d66:	fec40593          	addi	a1,s0,-20
    80005d6a:	4501                	li	a0,0
    80005d6c:	00000097          	auipc	ra,0x0
    80005d70:	cc2080e7          	jalr	-830(ra) # 80005a2e <argfd>
    return -1;
    80005d74:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005d76:	02054463          	bltz	a0,80005d9e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005d7a:	ffffc097          	auipc	ra,0xffffc
    80005d7e:	fe4080e7          	jalr	-28(ra) # 80001d5e <myproc>
    80005d82:	fec42783          	lw	a5,-20(s0)
    80005d86:	07e9                	addi	a5,a5,26
    80005d88:	078e                	slli	a5,a5,0x3
    80005d8a:	97aa                	add	a5,a5,a0
    80005d8c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005d90:	fe043503          	ld	a0,-32(s0)
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	272080e7          	jalr	626(ra) # 80005006 <fileclose>
  return 0;
    80005d9c:	4781                	li	a5,0
}
    80005d9e:	853e                	mv	a0,a5
    80005da0:	60e2                	ld	ra,24(sp)
    80005da2:	6442                	ld	s0,16(sp)
    80005da4:	6105                	addi	sp,sp,32
    80005da6:	8082                	ret

0000000080005da8 <sys_fstat>:
{
    80005da8:	1101                	addi	sp,sp,-32
    80005daa:	ec06                	sd	ra,24(sp)
    80005dac:	e822                	sd	s0,16(sp)
    80005dae:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005db0:	fe040593          	addi	a1,s0,-32
    80005db4:	4505                	li	a0,1
    80005db6:	ffffd097          	auipc	ra,0xffffd
    80005dba:	5da080e7          	jalr	1498(ra) # 80003390 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005dbe:	fe840613          	addi	a2,s0,-24
    80005dc2:	4581                	li	a1,0
    80005dc4:	4501                	li	a0,0
    80005dc6:	00000097          	auipc	ra,0x0
    80005dca:	c68080e7          	jalr	-920(ra) # 80005a2e <argfd>
    80005dce:	87aa                	mv	a5,a0
    return -1;
    80005dd0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005dd2:	0007ca63          	bltz	a5,80005de6 <sys_fstat+0x3e>
  return filestat(f, st);
    80005dd6:	fe043583          	ld	a1,-32(s0)
    80005dda:	fe843503          	ld	a0,-24(s0)
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	2f0080e7          	jalr	752(ra) # 800050ce <filestat>
}
    80005de6:	60e2                	ld	ra,24(sp)
    80005de8:	6442                	ld	s0,16(sp)
    80005dea:	6105                	addi	sp,sp,32
    80005dec:	8082                	ret

0000000080005dee <sys_link>:
{
    80005dee:	7169                	addi	sp,sp,-304
    80005df0:	f606                	sd	ra,296(sp)
    80005df2:	f222                	sd	s0,288(sp)
    80005df4:	ee26                	sd	s1,280(sp)
    80005df6:	ea4a                	sd	s2,272(sp)
    80005df8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005dfa:	08000613          	li	a2,128
    80005dfe:	ed040593          	addi	a1,s0,-304
    80005e02:	4501                	li	a0,0
    80005e04:	ffffd097          	auipc	ra,0xffffd
    80005e08:	5ac080e7          	jalr	1452(ra) # 800033b0 <argstr>
    return -1;
    80005e0c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e0e:	10054e63          	bltz	a0,80005f2a <sys_link+0x13c>
    80005e12:	08000613          	li	a2,128
    80005e16:	f5040593          	addi	a1,s0,-176
    80005e1a:	4505                	li	a0,1
    80005e1c:	ffffd097          	auipc	ra,0xffffd
    80005e20:	594080e7          	jalr	1428(ra) # 800033b0 <argstr>
    return -1;
    80005e24:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e26:	10054263          	bltz	a0,80005f2a <sys_link+0x13c>
  begin_op();
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	d10080e7          	jalr	-752(ra) # 80004b3a <begin_op>
  if((ip = namei(old)) == 0){
    80005e32:	ed040513          	addi	a0,s0,-304
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	ae8080e7          	jalr	-1304(ra) # 8000491e <namei>
    80005e3e:	84aa                	mv	s1,a0
    80005e40:	c551                	beqz	a0,80005ecc <sys_link+0xde>
  ilock(ip);
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	336080e7          	jalr	822(ra) # 80004178 <ilock>
  if(ip->type == T_DIR){
    80005e4a:	04449703          	lh	a4,68(s1)
    80005e4e:	4785                	li	a5,1
    80005e50:	08f70463          	beq	a4,a5,80005ed8 <sys_link+0xea>
  ip->nlink++;
    80005e54:	04a4d783          	lhu	a5,74(s1)
    80005e58:	2785                	addiw	a5,a5,1
    80005e5a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e5e:	8526                	mv	a0,s1
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	24e080e7          	jalr	590(ra) # 800040ae <iupdate>
  iunlock(ip);
    80005e68:	8526                	mv	a0,s1
    80005e6a:	ffffe097          	auipc	ra,0xffffe
    80005e6e:	3d0080e7          	jalr	976(ra) # 8000423a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005e72:	fd040593          	addi	a1,s0,-48
    80005e76:	f5040513          	addi	a0,s0,-176
    80005e7a:	fffff097          	auipc	ra,0xfffff
    80005e7e:	ac2080e7          	jalr	-1342(ra) # 8000493c <nameiparent>
    80005e82:	892a                	mv	s2,a0
    80005e84:	c935                	beqz	a0,80005ef8 <sys_link+0x10a>
  ilock(dp);
    80005e86:	ffffe097          	auipc	ra,0xffffe
    80005e8a:	2f2080e7          	jalr	754(ra) # 80004178 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005e8e:	00092703          	lw	a4,0(s2)
    80005e92:	409c                	lw	a5,0(s1)
    80005e94:	04f71d63          	bne	a4,a5,80005eee <sys_link+0x100>
    80005e98:	40d0                	lw	a2,4(s1)
    80005e9a:	fd040593          	addi	a1,s0,-48
    80005e9e:	854a                	mv	a0,s2
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	9cc080e7          	jalr	-1588(ra) # 8000486c <dirlink>
    80005ea8:	04054363          	bltz	a0,80005eee <sys_link+0x100>
  iunlockput(dp);
    80005eac:	854a                	mv	a0,s2
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	52c080e7          	jalr	1324(ra) # 800043da <iunlockput>
  iput(ip);
    80005eb6:	8526                	mv	a0,s1
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	47a080e7          	jalr	1146(ra) # 80004332 <iput>
  end_op();
    80005ec0:	fffff097          	auipc	ra,0xfffff
    80005ec4:	cfa080e7          	jalr	-774(ra) # 80004bba <end_op>
  return 0;
    80005ec8:	4781                	li	a5,0
    80005eca:	a085                	j	80005f2a <sys_link+0x13c>
    end_op();
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	cee080e7          	jalr	-786(ra) # 80004bba <end_op>
    return -1;
    80005ed4:	57fd                	li	a5,-1
    80005ed6:	a891                	j	80005f2a <sys_link+0x13c>
    iunlockput(ip);
    80005ed8:	8526                	mv	a0,s1
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	500080e7          	jalr	1280(ra) # 800043da <iunlockput>
    end_op();
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	cd8080e7          	jalr	-808(ra) # 80004bba <end_op>
    return -1;
    80005eea:	57fd                	li	a5,-1
    80005eec:	a83d                	j	80005f2a <sys_link+0x13c>
    iunlockput(dp);
    80005eee:	854a                	mv	a0,s2
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	4ea080e7          	jalr	1258(ra) # 800043da <iunlockput>
  ilock(ip);
    80005ef8:	8526                	mv	a0,s1
    80005efa:	ffffe097          	auipc	ra,0xffffe
    80005efe:	27e080e7          	jalr	638(ra) # 80004178 <ilock>
  ip->nlink--;
    80005f02:	04a4d783          	lhu	a5,74(s1)
    80005f06:	37fd                	addiw	a5,a5,-1
    80005f08:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f0c:	8526                	mv	a0,s1
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	1a0080e7          	jalr	416(ra) # 800040ae <iupdate>
  iunlockput(ip);
    80005f16:	8526                	mv	a0,s1
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	4c2080e7          	jalr	1218(ra) # 800043da <iunlockput>
  end_op();
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	c9a080e7          	jalr	-870(ra) # 80004bba <end_op>
  return -1;
    80005f28:	57fd                	li	a5,-1
}
    80005f2a:	853e                	mv	a0,a5
    80005f2c:	70b2                	ld	ra,296(sp)
    80005f2e:	7412                	ld	s0,288(sp)
    80005f30:	64f2                	ld	s1,280(sp)
    80005f32:	6952                	ld	s2,272(sp)
    80005f34:	6155                	addi	sp,sp,304
    80005f36:	8082                	ret

0000000080005f38 <sys_unlink>:
{
    80005f38:	7151                	addi	sp,sp,-240
    80005f3a:	f586                	sd	ra,232(sp)
    80005f3c:	f1a2                	sd	s0,224(sp)
    80005f3e:	eda6                	sd	s1,216(sp)
    80005f40:	e9ca                	sd	s2,208(sp)
    80005f42:	e5ce                	sd	s3,200(sp)
    80005f44:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005f46:	08000613          	li	a2,128
    80005f4a:	f3040593          	addi	a1,s0,-208
    80005f4e:	4501                	li	a0,0
    80005f50:	ffffd097          	auipc	ra,0xffffd
    80005f54:	460080e7          	jalr	1120(ra) # 800033b0 <argstr>
    80005f58:	18054163          	bltz	a0,800060da <sys_unlink+0x1a2>
  begin_op();
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	bde080e7          	jalr	-1058(ra) # 80004b3a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005f64:	fb040593          	addi	a1,s0,-80
    80005f68:	f3040513          	addi	a0,s0,-208
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	9d0080e7          	jalr	-1584(ra) # 8000493c <nameiparent>
    80005f74:	84aa                	mv	s1,a0
    80005f76:	c979                	beqz	a0,8000604c <sys_unlink+0x114>
  ilock(dp);
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	200080e7          	jalr	512(ra) # 80004178 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f80:	00003597          	auipc	a1,0x3
    80005f84:	a2058593          	addi	a1,a1,-1504 # 800089a0 <syscalls+0x2c8>
    80005f88:	fb040513          	addi	a0,s0,-80
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	6b6080e7          	jalr	1718(ra) # 80004642 <namecmp>
    80005f94:	14050a63          	beqz	a0,800060e8 <sys_unlink+0x1b0>
    80005f98:	00003597          	auipc	a1,0x3
    80005f9c:	a1058593          	addi	a1,a1,-1520 # 800089a8 <syscalls+0x2d0>
    80005fa0:	fb040513          	addi	a0,s0,-80
    80005fa4:	ffffe097          	auipc	ra,0xffffe
    80005fa8:	69e080e7          	jalr	1694(ra) # 80004642 <namecmp>
    80005fac:	12050e63          	beqz	a0,800060e8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005fb0:	f2c40613          	addi	a2,s0,-212
    80005fb4:	fb040593          	addi	a1,s0,-80
    80005fb8:	8526                	mv	a0,s1
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	6a2080e7          	jalr	1698(ra) # 8000465c <dirlookup>
    80005fc2:	892a                	mv	s2,a0
    80005fc4:	12050263          	beqz	a0,800060e8 <sys_unlink+0x1b0>
  ilock(ip);
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	1b0080e7          	jalr	432(ra) # 80004178 <ilock>
  if(ip->nlink < 1)
    80005fd0:	04a91783          	lh	a5,74(s2)
    80005fd4:	08f05263          	blez	a5,80006058 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005fd8:	04491703          	lh	a4,68(s2)
    80005fdc:	4785                	li	a5,1
    80005fde:	08f70563          	beq	a4,a5,80006068 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005fe2:	4641                	li	a2,16
    80005fe4:	4581                	li	a1,0
    80005fe6:	fc040513          	addi	a0,s0,-64
    80005fea:	ffffb097          	auipc	ra,0xffffb
    80005fee:	e3c080e7          	jalr	-452(ra) # 80000e26 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ff2:	4741                	li	a4,16
    80005ff4:	f2c42683          	lw	a3,-212(s0)
    80005ff8:	fc040613          	addi	a2,s0,-64
    80005ffc:	4581                	li	a1,0
    80005ffe:	8526                	mv	a0,s1
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	524080e7          	jalr	1316(ra) # 80004524 <writei>
    80006008:	47c1                	li	a5,16
    8000600a:	0af51563          	bne	a0,a5,800060b4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000600e:	04491703          	lh	a4,68(s2)
    80006012:	4785                	li	a5,1
    80006014:	0af70863          	beq	a4,a5,800060c4 <sys_unlink+0x18c>
  iunlockput(dp);
    80006018:	8526                	mv	a0,s1
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	3c0080e7          	jalr	960(ra) # 800043da <iunlockput>
  ip->nlink--;
    80006022:	04a95783          	lhu	a5,74(s2)
    80006026:	37fd                	addiw	a5,a5,-1
    80006028:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000602c:	854a                	mv	a0,s2
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	080080e7          	jalr	128(ra) # 800040ae <iupdate>
  iunlockput(ip);
    80006036:	854a                	mv	a0,s2
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	3a2080e7          	jalr	930(ra) # 800043da <iunlockput>
  end_op();
    80006040:	fffff097          	auipc	ra,0xfffff
    80006044:	b7a080e7          	jalr	-1158(ra) # 80004bba <end_op>
  return 0;
    80006048:	4501                	li	a0,0
    8000604a:	a84d                	j	800060fc <sys_unlink+0x1c4>
    end_op();
    8000604c:	fffff097          	auipc	ra,0xfffff
    80006050:	b6e080e7          	jalr	-1170(ra) # 80004bba <end_op>
    return -1;
    80006054:	557d                	li	a0,-1
    80006056:	a05d                	j	800060fc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006058:	00003517          	auipc	a0,0x3
    8000605c:	95850513          	addi	a0,a0,-1704 # 800089b0 <syscalls+0x2d8>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e4080e7          	jalr	1252(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006068:	04c92703          	lw	a4,76(s2)
    8000606c:	02000793          	li	a5,32
    80006070:	f6e7f9e3          	bgeu	a5,a4,80005fe2 <sys_unlink+0xaa>
    80006074:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006078:	4741                	li	a4,16
    8000607a:	86ce                	mv	a3,s3
    8000607c:	f1840613          	addi	a2,s0,-232
    80006080:	4581                	li	a1,0
    80006082:	854a                	mv	a0,s2
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	3a8080e7          	jalr	936(ra) # 8000442c <readi>
    8000608c:	47c1                	li	a5,16
    8000608e:	00f51b63          	bne	a0,a5,800060a4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006092:	f1845783          	lhu	a5,-232(s0)
    80006096:	e7a1                	bnez	a5,800060de <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006098:	29c1                	addiw	s3,s3,16
    8000609a:	04c92783          	lw	a5,76(s2)
    8000609e:	fcf9ede3          	bltu	s3,a5,80006078 <sys_unlink+0x140>
    800060a2:	b781                	j	80005fe2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800060a4:	00003517          	auipc	a0,0x3
    800060a8:	92450513          	addi	a0,a0,-1756 # 800089c8 <syscalls+0x2f0>
    800060ac:	ffffa097          	auipc	ra,0xffffa
    800060b0:	498080e7          	jalr	1176(ra) # 80000544 <panic>
    panic("unlink: writei");
    800060b4:	00003517          	auipc	a0,0x3
    800060b8:	92c50513          	addi	a0,a0,-1748 # 800089e0 <syscalls+0x308>
    800060bc:	ffffa097          	auipc	ra,0xffffa
    800060c0:	488080e7          	jalr	1160(ra) # 80000544 <panic>
    dp->nlink--;
    800060c4:	04a4d783          	lhu	a5,74(s1)
    800060c8:	37fd                	addiw	a5,a5,-1
    800060ca:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800060ce:	8526                	mv	a0,s1
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	fde080e7          	jalr	-34(ra) # 800040ae <iupdate>
    800060d8:	b781                	j	80006018 <sys_unlink+0xe0>
    return -1;
    800060da:	557d                	li	a0,-1
    800060dc:	a005                	j	800060fc <sys_unlink+0x1c4>
    iunlockput(ip);
    800060de:	854a                	mv	a0,s2
    800060e0:	ffffe097          	auipc	ra,0xffffe
    800060e4:	2fa080e7          	jalr	762(ra) # 800043da <iunlockput>
  iunlockput(dp);
    800060e8:	8526                	mv	a0,s1
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	2f0080e7          	jalr	752(ra) # 800043da <iunlockput>
  end_op();
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	ac8080e7          	jalr	-1336(ra) # 80004bba <end_op>
  return -1;
    800060fa:	557d                	li	a0,-1
}
    800060fc:	70ae                	ld	ra,232(sp)
    800060fe:	740e                	ld	s0,224(sp)
    80006100:	64ee                	ld	s1,216(sp)
    80006102:	694e                	ld	s2,208(sp)
    80006104:	69ae                	ld	s3,200(sp)
    80006106:	616d                	addi	sp,sp,240
    80006108:	8082                	ret

000000008000610a <sys_open>:

uint64
sys_open(void)
{
    8000610a:	7131                	addi	sp,sp,-192
    8000610c:	fd06                	sd	ra,184(sp)
    8000610e:	f922                	sd	s0,176(sp)
    80006110:	f526                	sd	s1,168(sp)
    80006112:	f14a                	sd	s2,160(sp)
    80006114:	ed4e                	sd	s3,152(sp)
    80006116:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006118:	f4c40593          	addi	a1,s0,-180
    8000611c:	4505                	li	a0,1
    8000611e:	ffffd097          	auipc	ra,0xffffd
    80006122:	252080e7          	jalr	594(ra) # 80003370 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006126:	08000613          	li	a2,128
    8000612a:	f5040593          	addi	a1,s0,-176
    8000612e:	4501                	li	a0,0
    80006130:	ffffd097          	auipc	ra,0xffffd
    80006134:	280080e7          	jalr	640(ra) # 800033b0 <argstr>
    80006138:	87aa                	mv	a5,a0
    return -1;
    8000613a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000613c:	0a07c963          	bltz	a5,800061ee <sys_open+0xe4>

  begin_op();
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	9fa080e7          	jalr	-1542(ra) # 80004b3a <begin_op>

  if(omode & O_CREATE){
    80006148:	f4c42783          	lw	a5,-180(s0)
    8000614c:	2007f793          	andi	a5,a5,512
    80006150:	cfc5                	beqz	a5,80006208 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006152:	4681                	li	a3,0
    80006154:	4601                	li	a2,0
    80006156:	4589                	li	a1,2
    80006158:	f5040513          	addi	a0,s0,-176
    8000615c:	00000097          	auipc	ra,0x0
    80006160:	974080e7          	jalr	-1676(ra) # 80005ad0 <create>
    80006164:	84aa                	mv	s1,a0
    if(ip == 0){
    80006166:	c959                	beqz	a0,800061fc <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006168:	04449703          	lh	a4,68(s1)
    8000616c:	478d                	li	a5,3
    8000616e:	00f71763          	bne	a4,a5,8000617c <sys_open+0x72>
    80006172:	0464d703          	lhu	a4,70(s1)
    80006176:	47a5                	li	a5,9
    80006178:	0ce7ed63          	bltu	a5,a4,80006252 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000617c:	fffff097          	auipc	ra,0xfffff
    80006180:	dce080e7          	jalr	-562(ra) # 80004f4a <filealloc>
    80006184:	89aa                	mv	s3,a0
    80006186:	10050363          	beqz	a0,8000628c <sys_open+0x182>
    8000618a:	00000097          	auipc	ra,0x0
    8000618e:	904080e7          	jalr	-1788(ra) # 80005a8e <fdalloc>
    80006192:	892a                	mv	s2,a0
    80006194:	0e054763          	bltz	a0,80006282 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006198:	04449703          	lh	a4,68(s1)
    8000619c:	478d                	li	a5,3
    8000619e:	0cf70563          	beq	a4,a5,80006268 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800061a2:	4789                	li	a5,2
    800061a4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800061a8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800061ac:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800061b0:	f4c42783          	lw	a5,-180(s0)
    800061b4:	0017c713          	xori	a4,a5,1
    800061b8:	8b05                	andi	a4,a4,1
    800061ba:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800061be:	0037f713          	andi	a4,a5,3
    800061c2:	00e03733          	snez	a4,a4
    800061c6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800061ca:	4007f793          	andi	a5,a5,1024
    800061ce:	c791                	beqz	a5,800061da <sys_open+0xd0>
    800061d0:	04449703          	lh	a4,68(s1)
    800061d4:	4789                	li	a5,2
    800061d6:	0af70063          	beq	a4,a5,80006276 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800061da:	8526                	mv	a0,s1
    800061dc:	ffffe097          	auipc	ra,0xffffe
    800061e0:	05e080e7          	jalr	94(ra) # 8000423a <iunlock>
  end_op();
    800061e4:	fffff097          	auipc	ra,0xfffff
    800061e8:	9d6080e7          	jalr	-1578(ra) # 80004bba <end_op>

  return fd;
    800061ec:	854a                	mv	a0,s2
}
    800061ee:	70ea                	ld	ra,184(sp)
    800061f0:	744a                	ld	s0,176(sp)
    800061f2:	74aa                	ld	s1,168(sp)
    800061f4:	790a                	ld	s2,160(sp)
    800061f6:	69ea                	ld	s3,152(sp)
    800061f8:	6129                	addi	sp,sp,192
    800061fa:	8082                	ret
      end_op();
    800061fc:	fffff097          	auipc	ra,0xfffff
    80006200:	9be080e7          	jalr	-1602(ra) # 80004bba <end_op>
      return -1;
    80006204:	557d                	li	a0,-1
    80006206:	b7e5                	j	800061ee <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006208:	f5040513          	addi	a0,s0,-176
    8000620c:	ffffe097          	auipc	ra,0xffffe
    80006210:	712080e7          	jalr	1810(ra) # 8000491e <namei>
    80006214:	84aa                	mv	s1,a0
    80006216:	c905                	beqz	a0,80006246 <sys_open+0x13c>
    ilock(ip);
    80006218:	ffffe097          	auipc	ra,0xffffe
    8000621c:	f60080e7          	jalr	-160(ra) # 80004178 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006220:	04449703          	lh	a4,68(s1)
    80006224:	4785                	li	a5,1
    80006226:	f4f711e3          	bne	a4,a5,80006168 <sys_open+0x5e>
    8000622a:	f4c42783          	lw	a5,-180(s0)
    8000622e:	d7b9                	beqz	a5,8000617c <sys_open+0x72>
      iunlockput(ip);
    80006230:	8526                	mv	a0,s1
    80006232:	ffffe097          	auipc	ra,0xffffe
    80006236:	1a8080e7          	jalr	424(ra) # 800043da <iunlockput>
      end_op();
    8000623a:	fffff097          	auipc	ra,0xfffff
    8000623e:	980080e7          	jalr	-1664(ra) # 80004bba <end_op>
      return -1;
    80006242:	557d                	li	a0,-1
    80006244:	b76d                	j	800061ee <sys_open+0xe4>
      end_op();
    80006246:	fffff097          	auipc	ra,0xfffff
    8000624a:	974080e7          	jalr	-1676(ra) # 80004bba <end_op>
      return -1;
    8000624e:	557d                	li	a0,-1
    80006250:	bf79                	j	800061ee <sys_open+0xe4>
    iunlockput(ip);
    80006252:	8526                	mv	a0,s1
    80006254:	ffffe097          	auipc	ra,0xffffe
    80006258:	186080e7          	jalr	390(ra) # 800043da <iunlockput>
    end_op();
    8000625c:	fffff097          	auipc	ra,0xfffff
    80006260:	95e080e7          	jalr	-1698(ra) # 80004bba <end_op>
    return -1;
    80006264:	557d                	li	a0,-1
    80006266:	b761                	j	800061ee <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006268:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000626c:	04649783          	lh	a5,70(s1)
    80006270:	02f99223          	sh	a5,36(s3)
    80006274:	bf25                	j	800061ac <sys_open+0xa2>
    itrunc(ip);
    80006276:	8526                	mv	a0,s1
    80006278:	ffffe097          	auipc	ra,0xffffe
    8000627c:	00e080e7          	jalr	14(ra) # 80004286 <itrunc>
    80006280:	bfa9                	j	800061da <sys_open+0xd0>
      fileclose(f);
    80006282:	854e                	mv	a0,s3
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	d82080e7          	jalr	-638(ra) # 80005006 <fileclose>
    iunlockput(ip);
    8000628c:	8526                	mv	a0,s1
    8000628e:	ffffe097          	auipc	ra,0xffffe
    80006292:	14c080e7          	jalr	332(ra) # 800043da <iunlockput>
    end_op();
    80006296:	fffff097          	auipc	ra,0xfffff
    8000629a:	924080e7          	jalr	-1756(ra) # 80004bba <end_op>
    return -1;
    8000629e:	557d                	li	a0,-1
    800062a0:	b7b9                	j	800061ee <sys_open+0xe4>

00000000800062a2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800062a2:	7175                	addi	sp,sp,-144
    800062a4:	e506                	sd	ra,136(sp)
    800062a6:	e122                	sd	s0,128(sp)
    800062a8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800062aa:	fffff097          	auipc	ra,0xfffff
    800062ae:	890080e7          	jalr	-1904(ra) # 80004b3a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800062b2:	08000613          	li	a2,128
    800062b6:	f7040593          	addi	a1,s0,-144
    800062ba:	4501                	li	a0,0
    800062bc:	ffffd097          	auipc	ra,0xffffd
    800062c0:	0f4080e7          	jalr	244(ra) # 800033b0 <argstr>
    800062c4:	02054963          	bltz	a0,800062f6 <sys_mkdir+0x54>
    800062c8:	4681                	li	a3,0
    800062ca:	4601                	li	a2,0
    800062cc:	4585                	li	a1,1
    800062ce:	f7040513          	addi	a0,s0,-144
    800062d2:	fffff097          	auipc	ra,0xfffff
    800062d6:	7fe080e7          	jalr	2046(ra) # 80005ad0 <create>
    800062da:	cd11                	beqz	a0,800062f6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800062dc:	ffffe097          	auipc	ra,0xffffe
    800062e0:	0fe080e7          	jalr	254(ra) # 800043da <iunlockput>
  end_op();
    800062e4:	fffff097          	auipc	ra,0xfffff
    800062e8:	8d6080e7          	jalr	-1834(ra) # 80004bba <end_op>
  return 0;
    800062ec:	4501                	li	a0,0
}
    800062ee:	60aa                	ld	ra,136(sp)
    800062f0:	640a                	ld	s0,128(sp)
    800062f2:	6149                	addi	sp,sp,144
    800062f4:	8082                	ret
    end_op();
    800062f6:	fffff097          	auipc	ra,0xfffff
    800062fa:	8c4080e7          	jalr	-1852(ra) # 80004bba <end_op>
    return -1;
    800062fe:	557d                	li	a0,-1
    80006300:	b7fd                	j	800062ee <sys_mkdir+0x4c>

0000000080006302 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006302:	7135                	addi	sp,sp,-160
    80006304:	ed06                	sd	ra,152(sp)
    80006306:	e922                	sd	s0,144(sp)
    80006308:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000630a:	fffff097          	auipc	ra,0xfffff
    8000630e:	830080e7          	jalr	-2000(ra) # 80004b3a <begin_op>
  argint(1, &major);
    80006312:	f6c40593          	addi	a1,s0,-148
    80006316:	4505                	li	a0,1
    80006318:	ffffd097          	auipc	ra,0xffffd
    8000631c:	058080e7          	jalr	88(ra) # 80003370 <argint>
  argint(2, &minor);
    80006320:	f6840593          	addi	a1,s0,-152
    80006324:	4509                	li	a0,2
    80006326:	ffffd097          	auipc	ra,0xffffd
    8000632a:	04a080e7          	jalr	74(ra) # 80003370 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000632e:	08000613          	li	a2,128
    80006332:	f7040593          	addi	a1,s0,-144
    80006336:	4501                	li	a0,0
    80006338:	ffffd097          	auipc	ra,0xffffd
    8000633c:	078080e7          	jalr	120(ra) # 800033b0 <argstr>
    80006340:	02054b63          	bltz	a0,80006376 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006344:	f6841683          	lh	a3,-152(s0)
    80006348:	f6c41603          	lh	a2,-148(s0)
    8000634c:	458d                	li	a1,3
    8000634e:	f7040513          	addi	a0,s0,-144
    80006352:	fffff097          	auipc	ra,0xfffff
    80006356:	77e080e7          	jalr	1918(ra) # 80005ad0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000635a:	cd11                	beqz	a0,80006376 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000635c:	ffffe097          	auipc	ra,0xffffe
    80006360:	07e080e7          	jalr	126(ra) # 800043da <iunlockput>
  end_op();
    80006364:	fffff097          	auipc	ra,0xfffff
    80006368:	856080e7          	jalr	-1962(ra) # 80004bba <end_op>
  return 0;
    8000636c:	4501                	li	a0,0
}
    8000636e:	60ea                	ld	ra,152(sp)
    80006370:	644a                	ld	s0,144(sp)
    80006372:	610d                	addi	sp,sp,160
    80006374:	8082                	ret
    end_op();
    80006376:	fffff097          	auipc	ra,0xfffff
    8000637a:	844080e7          	jalr	-1980(ra) # 80004bba <end_op>
    return -1;
    8000637e:	557d                	li	a0,-1
    80006380:	b7fd                	j	8000636e <sys_mknod+0x6c>

0000000080006382 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006382:	7135                	addi	sp,sp,-160
    80006384:	ed06                	sd	ra,152(sp)
    80006386:	e922                	sd	s0,144(sp)
    80006388:	e526                	sd	s1,136(sp)
    8000638a:	e14a                	sd	s2,128(sp)
    8000638c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000638e:	ffffc097          	auipc	ra,0xffffc
    80006392:	9d0080e7          	jalr	-1584(ra) # 80001d5e <myproc>
    80006396:	892a                	mv	s2,a0
  
  begin_op();
    80006398:	ffffe097          	auipc	ra,0xffffe
    8000639c:	7a2080e7          	jalr	1954(ra) # 80004b3a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800063a0:	08000613          	li	a2,128
    800063a4:	f6040593          	addi	a1,s0,-160
    800063a8:	4501                	li	a0,0
    800063aa:	ffffd097          	auipc	ra,0xffffd
    800063ae:	006080e7          	jalr	6(ra) # 800033b0 <argstr>
    800063b2:	04054b63          	bltz	a0,80006408 <sys_chdir+0x86>
    800063b6:	f6040513          	addi	a0,s0,-160
    800063ba:	ffffe097          	auipc	ra,0xffffe
    800063be:	564080e7          	jalr	1380(ra) # 8000491e <namei>
    800063c2:	84aa                	mv	s1,a0
    800063c4:	c131                	beqz	a0,80006408 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800063c6:	ffffe097          	auipc	ra,0xffffe
    800063ca:	db2080e7          	jalr	-590(ra) # 80004178 <ilock>
  if(ip->type != T_DIR){
    800063ce:	04449703          	lh	a4,68(s1)
    800063d2:	4785                	li	a5,1
    800063d4:	04f71063          	bne	a4,a5,80006414 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800063d8:	8526                	mv	a0,s1
    800063da:	ffffe097          	auipc	ra,0xffffe
    800063de:	e60080e7          	jalr	-416(ra) # 8000423a <iunlock>
  iput(p->cwd);
    800063e2:	15093503          	ld	a0,336(s2)
    800063e6:	ffffe097          	auipc	ra,0xffffe
    800063ea:	f4c080e7          	jalr	-180(ra) # 80004332 <iput>
  end_op();
    800063ee:	ffffe097          	auipc	ra,0xffffe
    800063f2:	7cc080e7          	jalr	1996(ra) # 80004bba <end_op>
  p->cwd = ip;
    800063f6:	14993823          	sd	s1,336(s2)
  return 0;
    800063fa:	4501                	li	a0,0
}
    800063fc:	60ea                	ld	ra,152(sp)
    800063fe:	644a                	ld	s0,144(sp)
    80006400:	64aa                	ld	s1,136(sp)
    80006402:	690a                	ld	s2,128(sp)
    80006404:	610d                	addi	sp,sp,160
    80006406:	8082                	ret
    end_op();
    80006408:	ffffe097          	auipc	ra,0xffffe
    8000640c:	7b2080e7          	jalr	1970(ra) # 80004bba <end_op>
    return -1;
    80006410:	557d                	li	a0,-1
    80006412:	b7ed                	j	800063fc <sys_chdir+0x7a>
    iunlockput(ip);
    80006414:	8526                	mv	a0,s1
    80006416:	ffffe097          	auipc	ra,0xffffe
    8000641a:	fc4080e7          	jalr	-60(ra) # 800043da <iunlockput>
    end_op();
    8000641e:	ffffe097          	auipc	ra,0xffffe
    80006422:	79c080e7          	jalr	1948(ra) # 80004bba <end_op>
    return -1;
    80006426:	557d                	li	a0,-1
    80006428:	bfd1                	j	800063fc <sys_chdir+0x7a>

000000008000642a <sys_exec>:

uint64
sys_exec(void)
{
    8000642a:	7145                	addi	sp,sp,-464
    8000642c:	e786                	sd	ra,456(sp)
    8000642e:	e3a2                	sd	s0,448(sp)
    80006430:	ff26                	sd	s1,440(sp)
    80006432:	fb4a                	sd	s2,432(sp)
    80006434:	f74e                	sd	s3,424(sp)
    80006436:	f352                	sd	s4,416(sp)
    80006438:	ef56                	sd	s5,408(sp)
    8000643a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000643c:	e3840593          	addi	a1,s0,-456
    80006440:	4505                	li	a0,1
    80006442:	ffffd097          	auipc	ra,0xffffd
    80006446:	f4e080e7          	jalr	-178(ra) # 80003390 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000644a:	08000613          	li	a2,128
    8000644e:	f4040593          	addi	a1,s0,-192
    80006452:	4501                	li	a0,0
    80006454:	ffffd097          	auipc	ra,0xffffd
    80006458:	f5c080e7          	jalr	-164(ra) # 800033b0 <argstr>
    8000645c:	87aa                	mv	a5,a0
    return -1;
    8000645e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006460:	0c07c263          	bltz	a5,80006524 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006464:	10000613          	li	a2,256
    80006468:	4581                	li	a1,0
    8000646a:	e4040513          	addi	a0,s0,-448
    8000646e:	ffffb097          	auipc	ra,0xffffb
    80006472:	9b8080e7          	jalr	-1608(ra) # 80000e26 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006476:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000647a:	89a6                	mv	s3,s1
    8000647c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000647e:	02000a13          	li	s4,32
    80006482:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006486:	00391513          	slli	a0,s2,0x3
    8000648a:	e3040593          	addi	a1,s0,-464
    8000648e:	e3843783          	ld	a5,-456(s0)
    80006492:	953e                	add	a0,a0,a5
    80006494:	ffffd097          	auipc	ra,0xffffd
    80006498:	e3e080e7          	jalr	-450(ra) # 800032d2 <fetchaddr>
    8000649c:	02054a63          	bltz	a0,800064d0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800064a0:	e3043783          	ld	a5,-464(s0)
    800064a4:	c3b9                	beqz	a5,800064ea <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800064a6:	ffffa097          	auipc	ra,0xffffa
    800064aa:	756080e7          	jalr	1878(ra) # 80000bfc <kalloc>
    800064ae:	85aa                	mv	a1,a0
    800064b0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800064b4:	cd11                	beqz	a0,800064d0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800064b6:	6605                	lui	a2,0x1
    800064b8:	e3043503          	ld	a0,-464(s0)
    800064bc:	ffffd097          	auipc	ra,0xffffd
    800064c0:	e68080e7          	jalr	-408(ra) # 80003324 <fetchstr>
    800064c4:	00054663          	bltz	a0,800064d0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800064c8:	0905                	addi	s2,s2,1
    800064ca:	09a1                	addi	s3,s3,8
    800064cc:	fb491be3          	bne	s2,s4,80006482 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064d0:	10048913          	addi	s2,s1,256
    800064d4:	6088                	ld	a0,0(s1)
    800064d6:	c531                	beqz	a0,80006522 <sys_exec+0xf8>
    kfree(argv[i]);
    800064d8:	ffffa097          	auipc	ra,0xffffa
    800064dc:	5a2080e7          	jalr	1442(ra) # 80000a7a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064e0:	04a1                	addi	s1,s1,8
    800064e2:	ff2499e3          	bne	s1,s2,800064d4 <sys_exec+0xaa>
  return -1;
    800064e6:	557d                	li	a0,-1
    800064e8:	a835                	j	80006524 <sys_exec+0xfa>
      argv[i] = 0;
    800064ea:	0a8e                	slli	s5,s5,0x3
    800064ec:	fc040793          	addi	a5,s0,-64
    800064f0:	9abe                	add	s5,s5,a5
    800064f2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800064f6:	e4040593          	addi	a1,s0,-448
    800064fa:	f4040513          	addi	a0,s0,-192
    800064fe:	fffff097          	auipc	ra,0xfffff
    80006502:	190080e7          	jalr	400(ra) # 8000568e <exec>
    80006506:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006508:	10048993          	addi	s3,s1,256
    8000650c:	6088                	ld	a0,0(s1)
    8000650e:	c901                	beqz	a0,8000651e <sys_exec+0xf4>
    kfree(argv[i]);
    80006510:	ffffa097          	auipc	ra,0xffffa
    80006514:	56a080e7          	jalr	1386(ra) # 80000a7a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006518:	04a1                	addi	s1,s1,8
    8000651a:	ff3499e3          	bne	s1,s3,8000650c <sys_exec+0xe2>
  return ret;
    8000651e:	854a                	mv	a0,s2
    80006520:	a011                	j	80006524 <sys_exec+0xfa>
  return -1;
    80006522:	557d                	li	a0,-1
}
    80006524:	60be                	ld	ra,456(sp)
    80006526:	641e                	ld	s0,448(sp)
    80006528:	74fa                	ld	s1,440(sp)
    8000652a:	795a                	ld	s2,432(sp)
    8000652c:	79ba                	ld	s3,424(sp)
    8000652e:	7a1a                	ld	s4,416(sp)
    80006530:	6afa                	ld	s5,408(sp)
    80006532:	6179                	addi	sp,sp,464
    80006534:	8082                	ret

0000000080006536 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006536:	7139                	addi	sp,sp,-64
    80006538:	fc06                	sd	ra,56(sp)
    8000653a:	f822                	sd	s0,48(sp)
    8000653c:	f426                	sd	s1,40(sp)
    8000653e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006540:	ffffc097          	auipc	ra,0xffffc
    80006544:	81e080e7          	jalr	-2018(ra) # 80001d5e <myproc>
    80006548:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000654a:	fd840593          	addi	a1,s0,-40
    8000654e:	4501                	li	a0,0
    80006550:	ffffd097          	auipc	ra,0xffffd
    80006554:	e40080e7          	jalr	-448(ra) # 80003390 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006558:	fc840593          	addi	a1,s0,-56
    8000655c:	fd040513          	addi	a0,s0,-48
    80006560:	fffff097          	auipc	ra,0xfffff
    80006564:	dd6080e7          	jalr	-554(ra) # 80005336 <pipealloc>
    return -1;
    80006568:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000656a:	0c054463          	bltz	a0,80006632 <sys_pipe+0xfc>
  fd0 = -1;
    8000656e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006572:	fd043503          	ld	a0,-48(s0)
    80006576:	fffff097          	auipc	ra,0xfffff
    8000657a:	518080e7          	jalr	1304(ra) # 80005a8e <fdalloc>
    8000657e:	fca42223          	sw	a0,-60(s0)
    80006582:	08054b63          	bltz	a0,80006618 <sys_pipe+0xe2>
    80006586:	fc843503          	ld	a0,-56(s0)
    8000658a:	fffff097          	auipc	ra,0xfffff
    8000658e:	504080e7          	jalr	1284(ra) # 80005a8e <fdalloc>
    80006592:	fca42023          	sw	a0,-64(s0)
    80006596:	06054863          	bltz	a0,80006606 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000659a:	4691                	li	a3,4
    8000659c:	fc440613          	addi	a2,s0,-60
    800065a0:	fd843583          	ld	a1,-40(s0)
    800065a4:	68a8                	ld	a0,80(s1)
    800065a6:	ffffb097          	auipc	ra,0xffffb
    800065aa:	204080e7          	jalr	516(ra) # 800017aa <copyout>
    800065ae:	02054063          	bltz	a0,800065ce <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800065b2:	4691                	li	a3,4
    800065b4:	fc040613          	addi	a2,s0,-64
    800065b8:	fd843583          	ld	a1,-40(s0)
    800065bc:	0591                	addi	a1,a1,4
    800065be:	68a8                	ld	a0,80(s1)
    800065c0:	ffffb097          	auipc	ra,0xffffb
    800065c4:	1ea080e7          	jalr	490(ra) # 800017aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800065c8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800065ca:	06055463          	bgez	a0,80006632 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800065ce:	fc442783          	lw	a5,-60(s0)
    800065d2:	07e9                	addi	a5,a5,26
    800065d4:	078e                	slli	a5,a5,0x3
    800065d6:	97a6                	add	a5,a5,s1
    800065d8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800065dc:	fc042503          	lw	a0,-64(s0)
    800065e0:	0569                	addi	a0,a0,26
    800065e2:	050e                	slli	a0,a0,0x3
    800065e4:	94aa                	add	s1,s1,a0
    800065e6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800065ea:	fd043503          	ld	a0,-48(s0)
    800065ee:	fffff097          	auipc	ra,0xfffff
    800065f2:	a18080e7          	jalr	-1512(ra) # 80005006 <fileclose>
    fileclose(wf);
    800065f6:	fc843503          	ld	a0,-56(s0)
    800065fa:	fffff097          	auipc	ra,0xfffff
    800065fe:	a0c080e7          	jalr	-1524(ra) # 80005006 <fileclose>
    return -1;
    80006602:	57fd                	li	a5,-1
    80006604:	a03d                	j	80006632 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006606:	fc442783          	lw	a5,-60(s0)
    8000660a:	0007c763          	bltz	a5,80006618 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000660e:	07e9                	addi	a5,a5,26
    80006610:	078e                	slli	a5,a5,0x3
    80006612:	94be                	add	s1,s1,a5
    80006614:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006618:	fd043503          	ld	a0,-48(s0)
    8000661c:	fffff097          	auipc	ra,0xfffff
    80006620:	9ea080e7          	jalr	-1558(ra) # 80005006 <fileclose>
    fileclose(wf);
    80006624:	fc843503          	ld	a0,-56(s0)
    80006628:	fffff097          	auipc	ra,0xfffff
    8000662c:	9de080e7          	jalr	-1570(ra) # 80005006 <fileclose>
    return -1;
    80006630:	57fd                	li	a5,-1
}
    80006632:	853e                	mv	a0,a5
    80006634:	70e2                	ld	ra,56(sp)
    80006636:	7442                	ld	s0,48(sp)
    80006638:	74a2                	ld	s1,40(sp)
    8000663a:	6121                	addi	sp,sp,64
    8000663c:	8082                	ret
	...

0000000080006640 <kernelvec>:
    80006640:	7111                	addi	sp,sp,-256
    80006642:	e006                	sd	ra,0(sp)
    80006644:	e40a                	sd	sp,8(sp)
    80006646:	e80e                	sd	gp,16(sp)
    80006648:	ec12                	sd	tp,24(sp)
    8000664a:	f016                	sd	t0,32(sp)
    8000664c:	f41a                	sd	t1,40(sp)
    8000664e:	f81e                	sd	t2,48(sp)
    80006650:	fc22                	sd	s0,56(sp)
    80006652:	e0a6                	sd	s1,64(sp)
    80006654:	e4aa                	sd	a0,72(sp)
    80006656:	e8ae                	sd	a1,80(sp)
    80006658:	ecb2                	sd	a2,88(sp)
    8000665a:	f0b6                	sd	a3,96(sp)
    8000665c:	f4ba                	sd	a4,104(sp)
    8000665e:	f8be                	sd	a5,112(sp)
    80006660:	fcc2                	sd	a6,120(sp)
    80006662:	e146                	sd	a7,128(sp)
    80006664:	e54a                	sd	s2,136(sp)
    80006666:	e94e                	sd	s3,144(sp)
    80006668:	ed52                	sd	s4,152(sp)
    8000666a:	f156                	sd	s5,160(sp)
    8000666c:	f55a                	sd	s6,168(sp)
    8000666e:	f95e                	sd	s7,176(sp)
    80006670:	fd62                	sd	s8,184(sp)
    80006672:	e1e6                	sd	s9,192(sp)
    80006674:	e5ea                	sd	s10,200(sp)
    80006676:	e9ee                	sd	s11,208(sp)
    80006678:	edf2                	sd	t3,216(sp)
    8000667a:	f1f6                	sd	t4,224(sp)
    8000667c:	f5fa                	sd	t5,232(sp)
    8000667e:	f9fe                	sd	t6,240(sp)
    80006680:	b21fc0ef          	jal	ra,800031a0 <kerneltrap>
    80006684:	6082                	ld	ra,0(sp)
    80006686:	6122                	ld	sp,8(sp)
    80006688:	61c2                	ld	gp,16(sp)
    8000668a:	7282                	ld	t0,32(sp)
    8000668c:	7322                	ld	t1,40(sp)
    8000668e:	73c2                	ld	t2,48(sp)
    80006690:	7462                	ld	s0,56(sp)
    80006692:	6486                	ld	s1,64(sp)
    80006694:	6526                	ld	a0,72(sp)
    80006696:	65c6                	ld	a1,80(sp)
    80006698:	6666                	ld	a2,88(sp)
    8000669a:	7686                	ld	a3,96(sp)
    8000669c:	7726                	ld	a4,104(sp)
    8000669e:	77c6                	ld	a5,112(sp)
    800066a0:	7866                	ld	a6,120(sp)
    800066a2:	688a                	ld	a7,128(sp)
    800066a4:	692a                	ld	s2,136(sp)
    800066a6:	69ca                	ld	s3,144(sp)
    800066a8:	6a6a                	ld	s4,152(sp)
    800066aa:	7a8a                	ld	s5,160(sp)
    800066ac:	7b2a                	ld	s6,168(sp)
    800066ae:	7bca                	ld	s7,176(sp)
    800066b0:	7c6a                	ld	s8,184(sp)
    800066b2:	6c8e                	ld	s9,192(sp)
    800066b4:	6d2e                	ld	s10,200(sp)
    800066b6:	6dce                	ld	s11,208(sp)
    800066b8:	6e6e                	ld	t3,216(sp)
    800066ba:	7e8e                	ld	t4,224(sp)
    800066bc:	7f2e                	ld	t5,232(sp)
    800066be:	7fce                	ld	t6,240(sp)
    800066c0:	6111                	addi	sp,sp,256
    800066c2:	10200073          	sret
    800066c6:	00000013          	nop
    800066ca:	00000013          	nop
    800066ce:	0001                	nop

00000000800066d0 <timervec>:
    800066d0:	34051573          	csrrw	a0,mscratch,a0
    800066d4:	e10c                	sd	a1,0(a0)
    800066d6:	e510                	sd	a2,8(a0)
    800066d8:	e914                	sd	a3,16(a0)
    800066da:	6d0c                	ld	a1,24(a0)
    800066dc:	7110                	ld	a2,32(a0)
    800066de:	6194                	ld	a3,0(a1)
    800066e0:	96b2                	add	a3,a3,a2
    800066e2:	e194                	sd	a3,0(a1)
    800066e4:	4589                	li	a1,2
    800066e6:	14459073          	csrw	sip,a1
    800066ea:	6914                	ld	a3,16(a0)
    800066ec:	6510                	ld	a2,8(a0)
    800066ee:	610c                	ld	a1,0(a0)
    800066f0:	34051573          	csrrw	a0,mscratch,a0
    800066f4:	30200073          	mret
	...

00000000800066fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800066fa:	1141                	addi	sp,sp,-16
    800066fc:	e422                	sd	s0,8(sp)
    800066fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006700:	0c0007b7          	lui	a5,0xc000
    80006704:	4705                	li	a4,1
    80006706:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006708:	c3d8                	sw	a4,4(a5)
}
    8000670a:	6422                	ld	s0,8(sp)
    8000670c:	0141                	addi	sp,sp,16
    8000670e:	8082                	ret

0000000080006710 <plicinithart>:

void
plicinithart(void)
{
    80006710:	1141                	addi	sp,sp,-16
    80006712:	e406                	sd	ra,8(sp)
    80006714:	e022                	sd	s0,0(sp)
    80006716:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006718:	ffffb097          	auipc	ra,0xffffb
    8000671c:	61a080e7          	jalr	1562(ra) # 80001d32 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006720:	0085171b          	slliw	a4,a0,0x8
    80006724:	0c0027b7          	lui	a5,0xc002
    80006728:	97ba                	add	a5,a5,a4
    8000672a:	40200713          	li	a4,1026
    8000672e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006732:	00d5151b          	slliw	a0,a0,0xd
    80006736:	0c2017b7          	lui	a5,0xc201
    8000673a:	953e                	add	a0,a0,a5
    8000673c:	00052023          	sw	zero,0(a0)
}
    80006740:	60a2                	ld	ra,8(sp)
    80006742:	6402                	ld	s0,0(sp)
    80006744:	0141                	addi	sp,sp,16
    80006746:	8082                	ret

0000000080006748 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006748:	1141                	addi	sp,sp,-16
    8000674a:	e406                	sd	ra,8(sp)
    8000674c:	e022                	sd	s0,0(sp)
    8000674e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006750:	ffffb097          	auipc	ra,0xffffb
    80006754:	5e2080e7          	jalr	1506(ra) # 80001d32 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006758:	00d5179b          	slliw	a5,a0,0xd
    8000675c:	0c201537          	lui	a0,0xc201
    80006760:	953e                	add	a0,a0,a5
  return irq;
}
    80006762:	4148                	lw	a0,4(a0)
    80006764:	60a2                	ld	ra,8(sp)
    80006766:	6402                	ld	s0,0(sp)
    80006768:	0141                	addi	sp,sp,16
    8000676a:	8082                	ret

000000008000676c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000676c:	1101                	addi	sp,sp,-32
    8000676e:	ec06                	sd	ra,24(sp)
    80006770:	e822                	sd	s0,16(sp)
    80006772:	e426                	sd	s1,8(sp)
    80006774:	1000                	addi	s0,sp,32
    80006776:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006778:	ffffb097          	auipc	ra,0xffffb
    8000677c:	5ba080e7          	jalr	1466(ra) # 80001d32 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006780:	00d5151b          	slliw	a0,a0,0xd
    80006784:	0c2017b7          	lui	a5,0xc201
    80006788:	97aa                	add	a5,a5,a0
    8000678a:	c3c4                	sw	s1,4(a5)
}
    8000678c:	60e2                	ld	ra,24(sp)
    8000678e:	6442                	ld	s0,16(sp)
    80006790:	64a2                	ld	s1,8(sp)
    80006792:	6105                	addi	sp,sp,32
    80006794:	8082                	ret

0000000080006796 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006796:	1141                	addi	sp,sp,-16
    80006798:	e406                	sd	ra,8(sp)
    8000679a:	e022                	sd	s0,0(sp)
    8000679c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000679e:	479d                	li	a5,7
    800067a0:	04a7cc63          	blt	a5,a0,800067f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800067a4:	0023e797          	auipc	a5,0x23e
    800067a8:	3dc78793          	addi	a5,a5,988 # 80244b80 <disk>
    800067ac:	97aa                	add	a5,a5,a0
    800067ae:	0187c783          	lbu	a5,24(a5)
    800067b2:	ebb9                	bnez	a5,80006808 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800067b4:	00451613          	slli	a2,a0,0x4
    800067b8:	0023e797          	auipc	a5,0x23e
    800067bc:	3c878793          	addi	a5,a5,968 # 80244b80 <disk>
    800067c0:	6394                	ld	a3,0(a5)
    800067c2:	96b2                	add	a3,a3,a2
    800067c4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800067c8:	6398                	ld	a4,0(a5)
    800067ca:	9732                	add	a4,a4,a2
    800067cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800067d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800067d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800067d8:	953e                	add	a0,a0,a5
    800067da:	4785                	li	a5,1
    800067dc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800067e0:	0023e517          	auipc	a0,0x23e
    800067e4:	3b850513          	addi	a0,a0,952 # 80244b98 <disk+0x18>
    800067e8:	ffffc097          	auipc	ra,0xffffc
    800067ec:	190080e7          	jalr	400(ra) # 80002978 <wakeup>
}
    800067f0:	60a2                	ld	ra,8(sp)
    800067f2:	6402                	ld	s0,0(sp)
    800067f4:	0141                	addi	sp,sp,16
    800067f6:	8082                	ret
    panic("free_desc 1");
    800067f8:	00002517          	auipc	a0,0x2
    800067fc:	1f850513          	addi	a0,a0,504 # 800089f0 <syscalls+0x318>
    80006800:	ffffa097          	auipc	ra,0xffffa
    80006804:	d44080e7          	jalr	-700(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006808:	00002517          	auipc	a0,0x2
    8000680c:	1f850513          	addi	a0,a0,504 # 80008a00 <syscalls+0x328>
    80006810:	ffffa097          	auipc	ra,0xffffa
    80006814:	d34080e7          	jalr	-716(ra) # 80000544 <panic>

0000000080006818 <virtio_disk_init>:
{
    80006818:	1101                	addi	sp,sp,-32
    8000681a:	ec06                	sd	ra,24(sp)
    8000681c:	e822                	sd	s0,16(sp)
    8000681e:	e426                	sd	s1,8(sp)
    80006820:	e04a                	sd	s2,0(sp)
    80006822:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006824:	00002597          	auipc	a1,0x2
    80006828:	1ec58593          	addi	a1,a1,492 # 80008a10 <syscalls+0x338>
    8000682c:	0023e517          	auipc	a0,0x23e
    80006830:	47c50513          	addi	a0,a0,1148 # 80244ca8 <disk+0x128>
    80006834:	ffffa097          	auipc	ra,0xffffa
    80006838:	466080e7          	jalr	1126(ra) # 80000c9a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000683c:	100017b7          	lui	a5,0x10001
    80006840:	4398                	lw	a4,0(a5)
    80006842:	2701                	sext.w	a4,a4
    80006844:	747277b7          	lui	a5,0x74727
    80006848:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000684c:	14f71e63          	bne	a4,a5,800069a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006850:	100017b7          	lui	a5,0x10001
    80006854:	43dc                	lw	a5,4(a5)
    80006856:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006858:	4709                	li	a4,2
    8000685a:	14e79763          	bne	a5,a4,800069a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000685e:	100017b7          	lui	a5,0x10001
    80006862:	479c                	lw	a5,8(a5)
    80006864:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006866:	14e79163          	bne	a5,a4,800069a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000686a:	100017b7          	lui	a5,0x10001
    8000686e:	47d8                	lw	a4,12(a5)
    80006870:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006872:	554d47b7          	lui	a5,0x554d4
    80006876:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000687a:	12f71763          	bne	a4,a5,800069a8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000687e:	100017b7          	lui	a5,0x10001
    80006882:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006886:	4705                	li	a4,1
    80006888:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000688a:	470d                	li	a4,3
    8000688c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000688e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006890:	c7ffe737          	lui	a4,0xc7ffe
    80006894:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47db9a9f>
    80006898:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000689a:	2701                	sext.w	a4,a4
    8000689c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000689e:	472d                	li	a4,11
    800068a0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800068a2:	0707a903          	lw	s2,112(a5)
    800068a6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800068a8:	00897793          	andi	a5,s2,8
    800068ac:	10078663          	beqz	a5,800069b8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800068b0:	100017b7          	lui	a5,0x10001
    800068b4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800068b8:	43fc                	lw	a5,68(a5)
    800068ba:	2781                	sext.w	a5,a5
    800068bc:	10079663          	bnez	a5,800069c8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800068c0:	100017b7          	lui	a5,0x10001
    800068c4:	5bdc                	lw	a5,52(a5)
    800068c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800068c8:	10078863          	beqz	a5,800069d8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800068cc:	471d                	li	a4,7
    800068ce:	10f77d63          	bgeu	a4,a5,800069e8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800068d2:	ffffa097          	auipc	ra,0xffffa
    800068d6:	32a080e7          	jalr	810(ra) # 80000bfc <kalloc>
    800068da:	0023e497          	auipc	s1,0x23e
    800068de:	2a648493          	addi	s1,s1,678 # 80244b80 <disk>
    800068e2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800068e4:	ffffa097          	auipc	ra,0xffffa
    800068e8:	318080e7          	jalr	792(ra) # 80000bfc <kalloc>
    800068ec:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800068ee:	ffffa097          	auipc	ra,0xffffa
    800068f2:	30e080e7          	jalr	782(ra) # 80000bfc <kalloc>
    800068f6:	87aa                	mv	a5,a0
    800068f8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800068fa:	6088                	ld	a0,0(s1)
    800068fc:	cd75                	beqz	a0,800069f8 <virtio_disk_init+0x1e0>
    800068fe:	0023e717          	auipc	a4,0x23e
    80006902:	28a73703          	ld	a4,650(a4) # 80244b88 <disk+0x8>
    80006906:	cb6d                	beqz	a4,800069f8 <virtio_disk_init+0x1e0>
    80006908:	cbe5                	beqz	a5,800069f8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000690a:	6605                	lui	a2,0x1
    8000690c:	4581                	li	a1,0
    8000690e:	ffffa097          	auipc	ra,0xffffa
    80006912:	518080e7          	jalr	1304(ra) # 80000e26 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006916:	0023e497          	auipc	s1,0x23e
    8000691a:	26a48493          	addi	s1,s1,618 # 80244b80 <disk>
    8000691e:	6605                	lui	a2,0x1
    80006920:	4581                	li	a1,0
    80006922:	6488                	ld	a0,8(s1)
    80006924:	ffffa097          	auipc	ra,0xffffa
    80006928:	502080e7          	jalr	1282(ra) # 80000e26 <memset>
  memset(disk.used, 0, PGSIZE);
    8000692c:	6605                	lui	a2,0x1
    8000692e:	4581                	li	a1,0
    80006930:	6888                	ld	a0,16(s1)
    80006932:	ffffa097          	auipc	ra,0xffffa
    80006936:	4f4080e7          	jalr	1268(ra) # 80000e26 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000693a:	100017b7          	lui	a5,0x10001
    8000693e:	4721                	li	a4,8
    80006940:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006942:	4098                	lw	a4,0(s1)
    80006944:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006948:	40d8                	lw	a4,4(s1)
    8000694a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000694e:	6498                	ld	a4,8(s1)
    80006950:	0007069b          	sext.w	a3,a4
    80006954:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006958:	9701                	srai	a4,a4,0x20
    8000695a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000695e:	6898                	ld	a4,16(s1)
    80006960:	0007069b          	sext.w	a3,a4
    80006964:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006968:	9701                	srai	a4,a4,0x20
    8000696a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000696e:	4685                	li	a3,1
    80006970:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006972:	4705                	li	a4,1
    80006974:	00d48c23          	sb	a3,24(s1)
    80006978:	00e48ca3          	sb	a4,25(s1)
    8000697c:	00e48d23          	sb	a4,26(s1)
    80006980:	00e48da3          	sb	a4,27(s1)
    80006984:	00e48e23          	sb	a4,28(s1)
    80006988:	00e48ea3          	sb	a4,29(s1)
    8000698c:	00e48f23          	sb	a4,30(s1)
    80006990:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006994:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006998:	0727a823          	sw	s2,112(a5)
}
    8000699c:	60e2                	ld	ra,24(sp)
    8000699e:	6442                	ld	s0,16(sp)
    800069a0:	64a2                	ld	s1,8(sp)
    800069a2:	6902                	ld	s2,0(sp)
    800069a4:	6105                	addi	sp,sp,32
    800069a6:	8082                	ret
    panic("could not find virtio disk");
    800069a8:	00002517          	auipc	a0,0x2
    800069ac:	07850513          	addi	a0,a0,120 # 80008a20 <syscalls+0x348>
    800069b0:	ffffa097          	auipc	ra,0xffffa
    800069b4:	b94080e7          	jalr	-1132(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    800069b8:	00002517          	auipc	a0,0x2
    800069bc:	08850513          	addi	a0,a0,136 # 80008a40 <syscalls+0x368>
    800069c0:	ffffa097          	auipc	ra,0xffffa
    800069c4:	b84080e7          	jalr	-1148(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800069c8:	00002517          	auipc	a0,0x2
    800069cc:	09850513          	addi	a0,a0,152 # 80008a60 <syscalls+0x388>
    800069d0:	ffffa097          	auipc	ra,0xffffa
    800069d4:	b74080e7          	jalr	-1164(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800069d8:	00002517          	auipc	a0,0x2
    800069dc:	0a850513          	addi	a0,a0,168 # 80008a80 <syscalls+0x3a8>
    800069e0:	ffffa097          	auipc	ra,0xffffa
    800069e4:	b64080e7          	jalr	-1180(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800069e8:	00002517          	auipc	a0,0x2
    800069ec:	0b850513          	addi	a0,a0,184 # 80008aa0 <syscalls+0x3c8>
    800069f0:	ffffa097          	auipc	ra,0xffffa
    800069f4:	b54080e7          	jalr	-1196(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800069f8:	00002517          	auipc	a0,0x2
    800069fc:	0c850513          	addi	a0,a0,200 # 80008ac0 <syscalls+0x3e8>
    80006a00:	ffffa097          	auipc	ra,0xffffa
    80006a04:	b44080e7          	jalr	-1212(ra) # 80000544 <panic>

0000000080006a08 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a08:	7159                	addi	sp,sp,-112
    80006a0a:	f486                	sd	ra,104(sp)
    80006a0c:	f0a2                	sd	s0,96(sp)
    80006a0e:	eca6                	sd	s1,88(sp)
    80006a10:	e8ca                	sd	s2,80(sp)
    80006a12:	e4ce                	sd	s3,72(sp)
    80006a14:	e0d2                	sd	s4,64(sp)
    80006a16:	fc56                	sd	s5,56(sp)
    80006a18:	f85a                	sd	s6,48(sp)
    80006a1a:	f45e                	sd	s7,40(sp)
    80006a1c:	f062                	sd	s8,32(sp)
    80006a1e:	ec66                	sd	s9,24(sp)
    80006a20:	e86a                	sd	s10,16(sp)
    80006a22:	1880                	addi	s0,sp,112
    80006a24:	892a                	mv	s2,a0
    80006a26:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006a28:	00c52c83          	lw	s9,12(a0)
    80006a2c:	001c9c9b          	slliw	s9,s9,0x1
    80006a30:	1c82                	slli	s9,s9,0x20
    80006a32:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006a36:	0023e517          	auipc	a0,0x23e
    80006a3a:	27250513          	addi	a0,a0,626 # 80244ca8 <disk+0x128>
    80006a3e:	ffffa097          	auipc	ra,0xffffa
    80006a42:	2ec080e7          	jalr	748(ra) # 80000d2a <acquire>
  for(int i = 0; i < 3; i++){
    80006a46:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006a48:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80006a4a:	0023eb17          	auipc	s6,0x23e
    80006a4e:	136b0b13          	addi	s6,s6,310 # 80244b80 <disk>
  for(int i = 0; i < 3; i++){
    80006a52:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006a54:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a56:	0023ec17          	auipc	s8,0x23e
    80006a5a:	252c0c13          	addi	s8,s8,594 # 80244ca8 <disk+0x128>
    80006a5e:	a8b5                	j	80006ada <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006a60:	00fb06b3          	add	a3,s6,a5
    80006a64:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006a68:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006a6a:	0207c563          	bltz	a5,80006a94 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006a6e:	2485                	addiw	s1,s1,1
    80006a70:	0711                	addi	a4,a4,4
    80006a72:	1f548a63          	beq	s1,s5,80006c66 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006a76:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006a78:	0023e697          	auipc	a3,0x23e
    80006a7c:	10868693          	addi	a3,a3,264 # 80244b80 <disk>
    80006a80:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006a82:	0186c583          	lbu	a1,24(a3)
    80006a86:	fde9                	bnez	a1,80006a60 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006a88:	2785                	addiw	a5,a5,1
    80006a8a:	0685                	addi	a3,a3,1
    80006a8c:	ff779be3          	bne	a5,s7,80006a82 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006a90:	57fd                	li	a5,-1
    80006a92:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006a94:	02905a63          	blez	s1,80006ac8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006a98:	f9042503          	lw	a0,-112(s0)
    80006a9c:	00000097          	auipc	ra,0x0
    80006aa0:	cfa080e7          	jalr	-774(ra) # 80006796 <free_desc>
      for(int j = 0; j < i; j++)
    80006aa4:	4785                	li	a5,1
    80006aa6:	0297d163          	bge	a5,s1,80006ac8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006aaa:	f9442503          	lw	a0,-108(s0)
    80006aae:	00000097          	auipc	ra,0x0
    80006ab2:	ce8080e7          	jalr	-792(ra) # 80006796 <free_desc>
      for(int j = 0; j < i; j++)
    80006ab6:	4789                	li	a5,2
    80006ab8:	0097d863          	bge	a5,s1,80006ac8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006abc:	f9842503          	lw	a0,-104(s0)
    80006ac0:	00000097          	auipc	ra,0x0
    80006ac4:	cd6080e7          	jalr	-810(ra) # 80006796 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006ac8:	85e2                	mv	a1,s8
    80006aca:	0023e517          	auipc	a0,0x23e
    80006ace:	0ce50513          	addi	a0,a0,206 # 80244b98 <disk+0x18>
    80006ad2:	ffffc097          	auipc	ra,0xffffc
    80006ad6:	bca080e7          	jalr	-1078(ra) # 8000269c <sleep>
  for(int i = 0; i < 3; i++){
    80006ada:	f9040713          	addi	a4,s0,-112
    80006ade:	84ce                	mv	s1,s3
    80006ae0:	bf59                	j	80006a76 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006ae2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006ae6:	00479693          	slli	a3,a5,0x4
    80006aea:	0023e797          	auipc	a5,0x23e
    80006aee:	09678793          	addi	a5,a5,150 # 80244b80 <disk>
    80006af2:	97b6                	add	a5,a5,a3
    80006af4:	4685                	li	a3,1
    80006af6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006af8:	0023e597          	auipc	a1,0x23e
    80006afc:	08858593          	addi	a1,a1,136 # 80244b80 <disk>
    80006b00:	00a60793          	addi	a5,a2,10
    80006b04:	0792                	slli	a5,a5,0x4
    80006b06:	97ae                	add	a5,a5,a1
    80006b08:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    80006b0c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b10:	f6070693          	addi	a3,a4,-160
    80006b14:	619c                	ld	a5,0(a1)
    80006b16:	97b6                	add	a5,a5,a3
    80006b18:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006b1a:	6188                	ld	a0,0(a1)
    80006b1c:	96aa                	add	a3,a3,a0
    80006b1e:	47c1                	li	a5,16
    80006b20:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006b22:	4785                	li	a5,1
    80006b24:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006b28:	f9442783          	lw	a5,-108(s0)
    80006b2c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006b30:	0792                	slli	a5,a5,0x4
    80006b32:	953e                	add	a0,a0,a5
    80006b34:	05890693          	addi	a3,s2,88
    80006b38:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006b3a:	6188                	ld	a0,0(a1)
    80006b3c:	97aa                	add	a5,a5,a0
    80006b3e:	40000693          	li	a3,1024
    80006b42:	c794                	sw	a3,8(a5)
  if(write)
    80006b44:	100d0d63          	beqz	s10,80006c5e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006b48:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006b4c:	00c7d683          	lhu	a3,12(a5)
    80006b50:	0016e693          	ori	a3,a3,1
    80006b54:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006b58:	f9842583          	lw	a1,-104(s0)
    80006b5c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006b60:	0023e697          	auipc	a3,0x23e
    80006b64:	02068693          	addi	a3,a3,32 # 80244b80 <disk>
    80006b68:	00260793          	addi	a5,a2,2
    80006b6c:	0792                	slli	a5,a5,0x4
    80006b6e:	97b6                	add	a5,a5,a3
    80006b70:	587d                	li	a6,-1
    80006b72:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006b76:	0592                	slli	a1,a1,0x4
    80006b78:	952e                	add	a0,a0,a1
    80006b7a:	f9070713          	addi	a4,a4,-112
    80006b7e:	9736                	add	a4,a4,a3
    80006b80:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006b82:	6298                	ld	a4,0(a3)
    80006b84:	972e                	add	a4,a4,a1
    80006b86:	4585                	li	a1,1
    80006b88:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006b8a:	4509                	li	a0,2
    80006b8c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006b90:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b94:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006b98:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b9c:	6698                	ld	a4,8(a3)
    80006b9e:	00275783          	lhu	a5,2(a4)
    80006ba2:	8b9d                	andi	a5,a5,7
    80006ba4:	0786                	slli	a5,a5,0x1
    80006ba6:	97ba                	add	a5,a5,a4
    80006ba8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    80006bac:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006bb0:	6698                	ld	a4,8(a3)
    80006bb2:	00275783          	lhu	a5,2(a4)
    80006bb6:	2785                	addiw	a5,a5,1
    80006bb8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006bbc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006bc0:	100017b7          	lui	a5,0x10001
    80006bc4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006bc8:	00492703          	lw	a4,4(s2)
    80006bcc:	4785                	li	a5,1
    80006bce:	02f71163          	bne	a4,a5,80006bf0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006bd2:	0023e997          	auipc	s3,0x23e
    80006bd6:	0d698993          	addi	s3,s3,214 # 80244ca8 <disk+0x128>
  while(b->disk == 1) {
    80006bda:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006bdc:	85ce                	mv	a1,s3
    80006bde:	854a                	mv	a0,s2
    80006be0:	ffffc097          	auipc	ra,0xffffc
    80006be4:	abc080e7          	jalr	-1348(ra) # 8000269c <sleep>
  while(b->disk == 1) {
    80006be8:	00492783          	lw	a5,4(s2)
    80006bec:	fe9788e3          	beq	a5,s1,80006bdc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006bf0:	f9042903          	lw	s2,-112(s0)
    80006bf4:	00290793          	addi	a5,s2,2
    80006bf8:	00479713          	slli	a4,a5,0x4
    80006bfc:	0023e797          	auipc	a5,0x23e
    80006c00:	f8478793          	addi	a5,a5,-124 # 80244b80 <disk>
    80006c04:	97ba                	add	a5,a5,a4
    80006c06:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006c0a:	0023e997          	auipc	s3,0x23e
    80006c0e:	f7698993          	addi	s3,s3,-138 # 80244b80 <disk>
    80006c12:	00491713          	slli	a4,s2,0x4
    80006c16:	0009b783          	ld	a5,0(s3)
    80006c1a:	97ba                	add	a5,a5,a4
    80006c1c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006c20:	854a                	mv	a0,s2
    80006c22:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006c26:	00000097          	auipc	ra,0x0
    80006c2a:	b70080e7          	jalr	-1168(ra) # 80006796 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006c2e:	8885                	andi	s1,s1,1
    80006c30:	f0ed                	bnez	s1,80006c12 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006c32:	0023e517          	auipc	a0,0x23e
    80006c36:	07650513          	addi	a0,a0,118 # 80244ca8 <disk+0x128>
    80006c3a:	ffffa097          	auipc	ra,0xffffa
    80006c3e:	1a4080e7          	jalr	420(ra) # 80000dde <release>
}
    80006c42:	70a6                	ld	ra,104(sp)
    80006c44:	7406                	ld	s0,96(sp)
    80006c46:	64e6                	ld	s1,88(sp)
    80006c48:	6946                	ld	s2,80(sp)
    80006c4a:	69a6                	ld	s3,72(sp)
    80006c4c:	6a06                	ld	s4,64(sp)
    80006c4e:	7ae2                	ld	s5,56(sp)
    80006c50:	7b42                	ld	s6,48(sp)
    80006c52:	7ba2                	ld	s7,40(sp)
    80006c54:	7c02                	ld	s8,32(sp)
    80006c56:	6ce2                	ld	s9,24(sp)
    80006c58:	6d42                	ld	s10,16(sp)
    80006c5a:	6165                	addi	sp,sp,112
    80006c5c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006c5e:	4689                	li	a3,2
    80006c60:	00d79623          	sh	a3,12(a5)
    80006c64:	b5e5                	j	80006b4c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c66:	f9042603          	lw	a2,-112(s0)
    80006c6a:	00a60713          	addi	a4,a2,10
    80006c6e:	0712                	slli	a4,a4,0x4
    80006c70:	0023e517          	auipc	a0,0x23e
    80006c74:	f1850513          	addi	a0,a0,-232 # 80244b88 <disk+0x8>
    80006c78:	953a                	add	a0,a0,a4
  if(write)
    80006c7a:	e60d14e3          	bnez	s10,80006ae2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006c7e:	00a60793          	addi	a5,a2,10
    80006c82:	00479693          	slli	a3,a5,0x4
    80006c86:	0023e797          	auipc	a5,0x23e
    80006c8a:	efa78793          	addi	a5,a5,-262 # 80244b80 <disk>
    80006c8e:	97b6                	add	a5,a5,a3
    80006c90:	0007a423          	sw	zero,8(a5)
    80006c94:	b595                	j	80006af8 <virtio_disk_rw+0xf0>

0000000080006c96 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006c96:	1101                	addi	sp,sp,-32
    80006c98:	ec06                	sd	ra,24(sp)
    80006c9a:	e822                	sd	s0,16(sp)
    80006c9c:	e426                	sd	s1,8(sp)
    80006c9e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006ca0:	0023e497          	auipc	s1,0x23e
    80006ca4:	ee048493          	addi	s1,s1,-288 # 80244b80 <disk>
    80006ca8:	0023e517          	auipc	a0,0x23e
    80006cac:	00050513          	mv	a0,a0
    80006cb0:	ffffa097          	auipc	ra,0xffffa
    80006cb4:	07a080e7          	jalr	122(ra) # 80000d2a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006cb8:	10001737          	lui	a4,0x10001
    80006cbc:	533c                	lw	a5,96(a4)
    80006cbe:	8b8d                	andi	a5,a5,3
    80006cc0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006cc2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006cc6:	689c                	ld	a5,16(s1)
    80006cc8:	0204d703          	lhu	a4,32(s1)
    80006ccc:	0027d783          	lhu	a5,2(a5)
    80006cd0:	04f70863          	beq	a4,a5,80006d20 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006cd4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006cd8:	6898                	ld	a4,16(s1)
    80006cda:	0204d783          	lhu	a5,32(s1)
    80006cde:	8b9d                	andi	a5,a5,7
    80006ce0:	078e                	slli	a5,a5,0x3
    80006ce2:	97ba                	add	a5,a5,a4
    80006ce4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ce6:	00278713          	addi	a4,a5,2
    80006cea:	0712                	slli	a4,a4,0x4
    80006cec:	9726                	add	a4,a4,s1
    80006cee:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006cf2:	e721                	bnez	a4,80006d3a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006cf4:	0789                	addi	a5,a5,2
    80006cf6:	0792                	slli	a5,a5,0x4
    80006cf8:	97a6                	add	a5,a5,s1
    80006cfa:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006cfc:	00052223          	sw	zero,4(a0) # 80244cac <disk+0x12c>
    wakeup(b);
    80006d00:	ffffc097          	auipc	ra,0xffffc
    80006d04:	c78080e7          	jalr	-904(ra) # 80002978 <wakeup>

    disk.used_idx += 1;
    80006d08:	0204d783          	lhu	a5,32(s1)
    80006d0c:	2785                	addiw	a5,a5,1
    80006d0e:	17c2                	slli	a5,a5,0x30
    80006d10:	93c1                	srli	a5,a5,0x30
    80006d12:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006d16:	6898                	ld	a4,16(s1)
    80006d18:	00275703          	lhu	a4,2(a4)
    80006d1c:	faf71ce3          	bne	a4,a5,80006cd4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006d20:	0023e517          	auipc	a0,0x23e
    80006d24:	f8850513          	addi	a0,a0,-120 # 80244ca8 <disk+0x128>
    80006d28:	ffffa097          	auipc	ra,0xffffa
    80006d2c:	0b6080e7          	jalr	182(ra) # 80000dde <release>
}
    80006d30:	60e2                	ld	ra,24(sp)
    80006d32:	6442                	ld	s0,16(sp)
    80006d34:	64a2                	ld	s1,8(sp)
    80006d36:	6105                	addi	sp,sp,32
    80006d38:	8082                	ret
      panic("virtio_disk_intr status");
    80006d3a:	00002517          	auipc	a0,0x2
    80006d3e:	d9e50513          	addi	a0,a0,-610 # 80008ad8 <syscalls+0x400>
    80006d42:	ffffa097          	auipc	ra,0xffffa
    80006d46:	802080e7          	jalr	-2046(ra) # 80000544 <panic>
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
