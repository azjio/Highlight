;unicode - DLL - compiler x86

Global Dim arr_rgb(2)
Global Dim arr_hsb(2)
Global num_item_color = 3

Structure NppData Align #PB_Structure_AlignC
	*_nppHandle
	*_scintillaMainHandle
	*_scintillaSecondHandle
EndStructure

Structure ShortcutKey Align #PB_Structure_AlignC
	_isCtrl.b
	_isAlt.b
	_isShift.b
	_key.u ;i
EndStructure

Structure FuncItem Align #PB_Structure_AlignC
	_itemName.s{64}
	*_pFunc
	_cmdID.i
	_init2Check.b
	*_pShortcutKey.ShortcutKey
EndStructure

; ==================================
; 2 Обязательные процедуры DLL
; ==================================
Declare Highlight_All()
Declare Menu()

Prototype ScintillaDirect(sciptr, msg, param1 = 0, param2 = 0)


CompilerIf #PB_Compiler_LineNumbering=0
	CompilerError "Включите в настройках компилятора поддержку OnError"
CompilerEndIf

Procedure FatalError()
	Protected Result.s

	Result="Ошибка программы"

	CompilerIf #PB_Compiler_LineNumbering
		Result+" в строке "+ErrorLine()+", файла: "+GetFilePart(ErrorFile())
	CompilerEndIf

	Result+Chr(10)+Chr(10)+"Ошибка типа: "+Chr(34)+ErrorMessage()+Chr(34)
	MessageRequester("Ошибка программы!", Result, #MB_OK|#MB_ICONERROR)
EndProcedure

Procedure SaveFile_Buff(File.s, *Buff, Size)
	Protected Result = #False
	Protected ID = CreateFile(#PB_Any, File)
	If ID
		If WriteData(ID, *Buff, Size) = Size
			Result = #True
		EndIf
		CloseFile(ID)
	EndIf
	ProcedureReturn Result
EndProcedure


ProcedureDLL AttachProcess(Instance)
	;
	;<< Когда Notepad++ задействовал этот плагин при запуске Notepad++ >>
	; Ваш код инициализации здесь

	OnErrorCall(@FatalError())

	; Плаг может быть в AppData, нужен путь процесса Notepad++
	If OpenLibrary(0, "Scintilla.dll")=0
		If OpenLibrary(0, "..\Scintilla.dll")=0
			If OpenLibrary(0, "SciLexer.dll")=0
				OpenLibrary(0, "..\SciLexer.dll")
			EndIf
		EndIf
	EndIf

	Global Scintilla.ScintillaDirect=0

	; Если под номером 0 является открытая библиотека, получаем её функцию
	If IsLibrary(0)
		Scintilla = GetFunction(0, "Scintilla_DirectFunction")
	EndIf

	Global PathConfig$
	; Здесь определяем путь к конфигам, взависимости от портабельная или нет, WinXP или Win7 и выше
	; 	doLocalConf$ = GetCurrentDirectory() + "doLocalConf.xml"
	If FileSize(GetCurrentDirectory() + "doLocalConf.xml") < 0
		; If OSVersion() < #PB_OS_Windows_7 ; а что у нас с Vista?, может перенаправление сработает
			; PathConfig$ = GetHomeDirectory() + "Application Data\Notepad++\plugins\config"
		; Else
			; PathConfig$ = GetHomeDirectory() + "AppData\Roaming\Notepad++\plugins\config"
					; MessageRequester("Сообщение", "AppData" + #CRLF$ + doLocalConf$)
		; EndIf
		PathConfig$ = GetUserDirectory(#PB_Directory_ProgramData)+"Notepad++\plugins\config"
	Else
		PathConfig$ = GetCurrentDirectory() + "plugins\Config"
		; 		MessageRequester("Сообщение", "текущ" + #CRLF$ + doLocalConf$)
	EndIf


	Global Dim aLng.s(12)
	aLng(1) = "Highlight"
	aLng(2) = "Highlight text"
	aLng(3) = "Highlight"
	aLng(4) = "Clear"
	aLng(5) = "Clear all"
	aLng(6) = "Highlight Syntax"
	aLng(7) = "Add"
	aLng(8) = "Tone"
	aLng(9) = "Saturation"
	aLng(10) = "Brightness"
	aLng(11) = "Apply"
	aLng(12) = "Turn the mouse wheel here"

	; If FileSize(PathConfig$ + "\Highlight_Lang.ini")
	If OpenPreferences(PathConfig$ + "\Highlight_Lang.ini") ; открываем ini
		If PreferenceGroup("Lang")							; выбираем группу (секцию)
			ExaminePreferenceKeys()
			For i=1 To 12
				If NextPreferenceKey()
					aLng(i) = PreferenceKeyName()
				Else
					Break
				EndIf
			Next
		EndIf
		ClosePreferences()
	EndIf

	; Создаём конфиги если отсутствуют
	If FileSize(PathConfig$ + "\Highlight.ini") < 11
		SaveFile_Buff(PathConfig$ + "\Highlight.ini", ?Highlight_ini, ?Highlight_iniend - ?Highlight_ini)
	EndIf
	If FileSize(PathConfig$ + "\Highlight_Sample.ini") < 11
		SaveFile_Buff(PathConfig$ + "\Highlight_Sample.ini", ?Highlight_Sample_ini, ?Highlight_Sample_iniend - ?Highlight_Sample_ini)
	EndIf

	;
	Global NppData.NppData
	Global PluginName.s=aLng(1) ; Имя плагина
	Global Dim FuncsArray.FuncItem(1)   ; меню с 4 пунктами
	With FuncsArray(0)					; 1) пункт меню с быстрой клавишой
		\_itemName=aLng(2)
		\_pFunc=@Menu() ;@Highlight_All()
		\_pShortcutKey=AllocateStructure(ShortcutKey)
		\_pShortcutKey\_isCtrl=#True
		\_pShortcutKey\_isShift=#True
		\_pShortcutKey\_isAlt=#True
		\_pShortcutKey\_key=#VK_NEXT
	EndWith    ;2) разделитель в меню
			   ;    With FuncsArray(1)
			   ;       \_itemName=""
			   ;    EndWith
			   ;    With FuncsArray(2)                  ;3) пункт меню - чекбокс с галкой
			   ;       \_itemName="Custom Option 1"
			   ;       \_pFunc=@Highlight_All()
			   ;       \_init2Check=#True
			   ;    EndWith
			   ;    With FuncsArray(3)                  ;4) пункт меню - чекбокс без галки
			   ;       \_itemName="Custom Option 2"
			   ;       \_pFunc=@Highlight_All()
			   ;       \_init2Check=#False
			   ;    EndWith

EndProcedure

ProcedureDLL DetachProcess(Instance)
	;
	;<< Когда Notepad++ удаляет этот плагин >>
	; Ваш код очистки здесь
	;
	Protected i
	For i=0 To ArraySize(FuncsArray())
		FreeStructure(FuncsArray(i)\_pShortcutKey)
	Next
EndProcedure

; ==================================
; 5 Обязательные процедуры Notepad++
; ==================================

; NPP спрашивает, является ли плагин в юникоде, возвращаем "ДА"
ProcedureCDLL.i isUnicode()
	ProcedureReturn #PB_Compiler_Unicode
EndProcedure

; NPP спрашивает имя плагина
ProcedureCDLL.s getName()
	ProcedureReturn PluginName
EndProcedure

; NPP спрашивает, элементы меню, чтобы встроить их в меню "Плагины"
ProcedureCDLL.i getFuncsArray(*FuncsArraySize.Integer)
	*FuncsArraySize\i=ArraySize(FuncsArray())
	ProcedureReturn @FuncsArray()
EndProcedure

; компиляция взависимости от x86 или x64
CompilerIf #PB_Compiler_Processor = #PB_Processor_x86

	ProcedureCDLL setInfo(*NppHandle, *ScintillaMainHandle, *ScintillaSecondHandle)
		NppData\_nppHandle=*NppHandle
		NppData\_scintillaMainHandle=*ScintillaMainHandle
		NppData\_scintillaSecondHandle=*ScintillaSecondHandle
		;
		;<< Когда инфа Notepad++ изменилась >>
		; Ваш код здесь
		;
		; мессага на запуске
		; MessageRequester("PB Plugin for notepad++", ""+NppData\_scintillaMainHandle)
	EndProcedure

CompilerElse ; иначе для x64

	ProcedureCDLL setInfo(*Npp.NppData)

		CopyStructure(*Npp, NppData, NppData)
		;
		;<< Когда инфа Notepad++ изменилась >>
		; Ваш код здесь
	EndProcedure

CompilerEndIf

ProcedureCDLL beNotified(*SCNotification.SCNotification)
	;
	;<< Когда было получено уведомление scintilla Notepad++ >>
	; Ваш код здесь
	;
EndProcedure

ProcedureCDLL.i messageProc(Message, wParam, lParam)
	;
	;<< Когда было получено windows-сообщение Notepad++ >>
	; Ваш код здесь
	;
	ProcedureReturn #True
EndProcedure

; ==================================
; Ваши процедуры плагина
; ==================================


Procedure ScintillaMsg(*point, msg, param1 = 0, param2 = 0)
	If Scintilla And *point
		ProcedureReturn Scintilla(*point, msg, param1, param2)
	Else
		ProcedureReturn 0
	EndIf
EndProcedure

; Procedure MakeUTF8Text(text.s)
; Static buffer.s
; buffer=Space(StringByteLength(text, #PB_UTF8) + 1)
; PokeS(@buffer, text, -1, #PB_UTF8)
; ProcedureReturn @buffer
; EndProcedure

; Это надо будет убрать, так как #PB_UTF8 однозначно
CompilerIf #PB_Compiler_Unicode
	#TextEncoding = #PB_UTF8
CompilerElse
	#TextEncoding = #PB_Ascii
CompilerEndIf

; какой то аналог предыдущей процедуры
Procedure MakeScintillaText(text.s, *sciLength.Integer=0)
	Static sciLength : sciLength=StringByteLength(text, #TextEncoding)
	Static sciText.s : sciText = Space(sciLength)
	If *sciLength : *sciLength\i=sciLength : EndIf ;<--- Возвращает длину буфера scintilla  (требуется для определенной команды scintilla)
	PokeS(@sciText, text, -1, #TextEncoding)
	ProcedureReturn @sciText
EndProcedure

; Procedure Color(regex1$, n)
Procedure Color(*regex, regexLength, n)
	Protected txtLen, StartPos, EndPos, firstMatchPos
	; 	получить активность scintilla, их же 2 окна, с каким работаем, в какой курсор
	;MessageRequester("PB Plugin for notepad++", "Test... "+NppData\_scintillaMainHandle)

	*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл главного-первого окна scintilla текущей вкладки

	; Устанавливает режим поиска (REGEX + POSIX фигурные скобки)
	ScintillaMsg(*sciptr, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)

	; Устанавливает целевой диапазон поиска
	txtLen = ScintillaMsg(*sciptr, #SCI_GETTEXTLENGTH) ; получает длину текста
	; ScintillaMsg(*sciptr, #SCI_SETTARGETSTART, 0)	   ; от начала
	; ScintillaMsg(*sciptr, #SCI_SETTARGETEND, txtLen)   ; до конца, используя длину в качестве позиции последнего символа
	; ScintillaMsg(*sciptr, #SCI_INDICSETSTYLE, n, 17)	   ; #INDIC_TEXTFORE = 17 создат индикатор под номером 7 (занятые по уиолчанию 0, 1, 2)
	; ScintillaMsg(*sciptr, #SCI_INDICSETFORE, n, Color1) ; назначает цвет индикатора под номером 7 - зелёный
	; ScintillaMsg(*sciptr, #SCI_SETINDICATORCURRENT, 7) ; если тут задать текущий, то сбрасывается на втором шаге цикла

	; Поиск
	; regex=MakeScintillaText(regex1$, @regexLength) ; пока не понятно откуда взялось regexLength, пустая переменная в которую возвр. указатель, объявили внутри вызова что-ли
	EndPos = 0
	Repeat
		ScintillaMsg(*sciptr, #SCI_SETTARGETSTART, EndPos)	   ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
		ScintillaMsg(*sciptr, #SCI_SETTARGETEND, txtLen)	   ; до конца по длине текста
		firstMatchPos=ScintillaMsg(*sciptr, #SCI_SEARCHINTARGET, regexLength, *regex) ; возвращает позицию первого найденного. В параметрах длина искомого и указатель
		If firstMatchPos>-1															  ; если больше -1, то есть найдено, то
			StartPos=ScintillaMsg(*sciptr, #SCI_GETTARGETSTART)						  ; получает позицию начала найденного
			EndPos=ScintillaMsg(*sciptr, #SCI_GETTARGETEND)							  ; получает позицию конца найденного
		  ; ScintillaMsg(*sciptr, #SCI_GOTOPOS, EndPos) ; перемещает курсор к найденному, чтобы следить за происходящим
		  ; ScintillaMsg(*sciptr, #SCI_SETSEL, StartPos, EndPos)  ; выделяет текст используя позиции начала и конца
		  ; допустимые индикаторы с 9 до 30, остальные для собственных нужд
			ScintillaMsg(*sciptr, #SCI_SETINDICATORCURRENT, n)						  ; делает индикатор под номером 7 текущим
			ScintillaMsg(*sciptr, #SCI_INDICATORFILLRANGE, StartPos, EndPos - StartPos)  ; выделяет текст используя текущий индикатор

			; MessageRequester("Длина текста" + StrD(txtLen), "Найдено" + #TAB$ + StrD(firstMatchPos) + #CRLF$ + "начало" + #TAB$ + StrD(StartPos) + #CRLF$ + "конец" + #TAB$ + StrD(EndPos))
		Else
			Break
		EndIf
	ForEver
EndProcedure

IncludeFile "Form.pbf"

Procedure Highlight_All()
	Protected Color1.l, regex1$, n
	If OpenPreferences(PathConfig$ + "\Highlight_Sample.ini") ; открываем ini
		Lexer$ = GetGadgetText(#Combo_Sample)
		If PreferenceGroup(Lexer$) ; выбираем группу (секцию)
			ExaminePreferenceKeys()
			While NextPreferenceKey()
				n = Val(PreferenceKeyName())
				; Color1 = Val("$" + Mid(RBG$, 5, 2)+Mid(RBG$, 3, 2)+Mid(RBG$, 1, 2)) ; конвертирует RBG в BGR и преобразует в число
				regex1$ = PreferenceKeyValue()



				*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
				If ScintillaMsg(*sciptr, #SCI_GETCODEPAGE) = 0
					*MemoireID = UTF8(regex1$)
					If *MemoireID ; Если указатель получен, то
						*MemID_res = AllocateMemory(5000) ; Выделяем память на 5000 символов
						If *MemID_res					  ; Если указатель получен, то
							ScintillaMsg(*sciptr, #SCI_ENCODEDFROMUTF8, *MemoireID, *MemID_res)
							regex1$ = PeekS(*MemID_res) ; Считываем значение из области памяти
							FreeMemory(*MemID_res)
						EndIf
						FreeMemory(*MemoireID)
					EndIf
					Color(@regex1$, Len(regex1$), n)

					; Попытка конвертировать текст поиска в UTF-8, на самом деле он и так в UTF-8, а кроме этого есть функция UTF8(regex1$)
				ElseIf ScintillaMsg(*sciptr, #SCI_GETCODEPAGE) = 65001
					; MessageRequester("Кодировка", Str(ScintillaMsg(*sciptr, #SCI_GETCODEPAGE)))
					; MakeUTF8Text(regex1$)
					Color(MakeScintillaText(regex1$, @regexLength), @regexLength, n)
				EndIf

				; Color(regex1$, n)
				; Color(@regex1$, Len(regex1$), n)
				; n+1
			Wend
		EndIf
		ClosePreferences()
	EndIf
EndProcedure




; Procedure hsb_to_rgb(arr_hsb)
Procedure hsb_to_rgb()
	Protected sector
	Protected.f ff, pp, qq, tt
	Protected.f Dim af_rgb(2) ; создаём массивы в которых числа будут в диапазоне 0-1
	Protected.f Dim af_hsb(2)
	; Protected Dim arr_rgb(2)

	af_hsb(2) = arr_hsb(2) /100

	If arr_hsb(1) = 0 ; если серый, то одно значение всем
		arr_rgb(0)=Round(af_hsb(2)*255, #PB_Round_Nearest)
		arr_rgb(1)=arr_rgb(0)
		arr_rgb(2)=arr_rgb(0)
		; ProcedureReturn arr_rgb
	EndIf

	While arr_hsb(0)>=360 ; если тон задан большим запредельным числом, то
		arr_hsb(0)-360
	Wend

	af_hsb(1) = arr_hsb(1) / 100
	af_hsb(0) = arr_hsb(0) / 60
	; sector = Int(arr_hsb(0))
	sector = Round(af_hsb(0), #PB_Round_Down)

	ff=af_hsb(0) - sector
	pp=af_hsb(2)*(1-af_hsb(1))
	qq=af_hsb(2)*(1-af_hsb(1)*ff)
	tt=af_hsb(2)*(1-af_hsb(1)*(1-ff))

	Select sector
		Case 0
			af_rgb(0)=af_hsb(2)
			af_rgb(1)=tt
			af_rgb(2)=pp
		Case 1
			af_rgb(0)=qq
			af_rgb(1)=af_hsb(2)
			af_rgb(2)=pp
		Case 2
			af_rgb(0)=pp
			af_rgb(1)=af_hsb(2)
			af_rgb(2)=tt
		Case 3
			af_rgb(0)=pp
			af_rgb(1)=qq
			af_rgb(2)=af_hsb(2)
		Case 4
			af_rgb(0)=tt
			af_rgb(1)=pp
			af_rgb(2)=af_hsb(2)
		Default
			af_rgb(0)=af_hsb(2)
			af_rgb(1)=pp
			af_rgb(2)=qq
	EndSelect

	; RGB
	arr_rgb(0)=Round(af_rgb(0)*255, #PB_Round_Nearest)
	arr_rgb(1)=Round(af_rgb(1)*255, #PB_Round_Nearest)
	arr_rgb(2)=Round(af_rgb(2)*255, #PB_Round_Nearest)

	; BGR
	; arr_rgb(2)=Round(af_rgb(0)*255, #PB_Round_Nearest)
	; arr_rgb(1)=Round(af_rgb(1)*255, #PB_Round_Nearest)
	; arr_rgb(0)=Round(af_rgb(2)*255, #PB_Round_Nearest)

	; ProcedureReturn arr_rgb
EndProcedure


Procedure rgb_to_hsb()
	Protected.f min, max

	If arr_rgb(0)<=arr_rgb(1)
		min=arr_rgb(0)
		max=arr_rgb(1)
	Else
		min=arr_rgb(1)
		max=arr_rgb(0)
	EndIf

	If min>arr_rgb(2)
		min=arr_rgb(2)
	EndIf

	If max<arr_rgb(2)
		max=arr_rgb(2)
	EndIf

	If max = min
		arr_hsb(0)=0
	ElseIf max = arr_rgb(0) And arr_rgb(1)>=arr_rgb(2)
		arr_hsb(0)=60*(arr_rgb(1)-arr_rgb(2))/(max - min)
	ElseIf max = arr_rgb(0) And arr_rgb(1)<arr_rgb(2)
		arr_hsb(0)=60*(arr_rgb(1)-arr_rgb(2))/(max - min)+360
	ElseIf max = arr_rgb(1)
		arr_hsb(0)=60*(arr_rgb(2)-arr_rgb(0))/(max - min)+120
	ElseIf max = arr_rgb(2)
		arr_hsb(0)=60*(arr_rgb(0)-arr_rgb(1))/(max - min)+240
	EndIf

	If max = 0
		arr_hsb(1)=0
	Else
		arr_hsb(1)=(1-min/max)*100
	EndIf

	arr_hsb(2)=max/255*100

	arr_hsb(0)=Round(arr_hsb(0), #PB_Round_Nearest)
	arr_hsb(1)=Round(arr_hsb(1), #PB_Round_Nearest)
	arr_hsb(2)=Round(arr_hsb(2), #PB_Round_Nearest)

	; ProcedureReturn arr_hsb
EndProcedure



Procedure Slider_Chande_Color()
	arr_hsb(0) = GetGadgetState(#Slider1)
	arr_hsb(1) = GetGadgetState(#Slider2)
	arr_hsb(2) = GetGadgetState(#Slider3)
	hsb_to_rgb()
	rgb_color = RGB(arr_rgb(0), arr_rgb(1), arr_rgb(2))
	; n = GetGadgetItemData(#Combo_Color , GetGadgetState(#Combo_Color))
	; rgb_color = Val("$" + Mid(RBG$, 5, 2)+Mid(RBG$, 3, 2)+Mid(RBG$, 1, 2)) ; конвертирует RBG в BGR и преобразует в число
	*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
																					  ; ScintillaMsg(*sciptr, #SCI_INDICSETFORE, n, rgb_color)
	ScintillaMsg(*sciptr, #SCI_INDICSETFORE, num_item_color, rgb_color)
	SetGadgetColor(#Color, #PB_Gadget_BackColor, rgb_color)
	SetGadgetText(#EditColor , RSet(Hex(RGB(arr_rgb(2), arr_rgb(1), arr_rgb(0))), 6, "0"))
	; Protected RBG
	; RBG = Val("$" + Left(GetGadgetText(#Combo_Color), 6))
	; Item = GetGadgetState(#Combo_Color)
EndProcedure

Procedure Set_Slider_Color_Sel_Ind()
	Protected RBG
	*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
	RBG = ScintillaMsg(*sciptr, #SCI_INDICGETFORE, num_item_color)					  ; получает цвет
	; RBG = Val("$" + String$)
	arr_rgb(0) = Red(RBG)
	arr_rgb(1) = Green(RBG)
	arr_rgb(2) = Blue(RBG)
	rgb_to_hsb()
	SetGadgetState(#Slider1 , arr_hsb(0))
	SetGadgetState(#Slider2 , arr_hsb(1))
	SetGadgetState(#Slider3 , arr_hsb(2))

	SetGadgetText(#Hue, Str(arr_hsb(0)))
	SetGadgetText(#Satur, Str(arr_hsb(1)))
	SetGadgetText(#Bright, Str(arr_hsb(2)))

	SetGadgetText(#EditColor , RSet(Hex(RGB(arr_rgb(2), arr_rgb(1), arr_rgb(0))), 6, "0"))

	rgb_color = RGB(arr_rgb(0), arr_rgb(1), arr_rgb(2))
	SetGadgetColor(#Color, #PB_Gadget_BackColor, rgb_color)
EndProcedure


Procedure Set_Slider_Color_RGB()
	Protected RBG
	String$ = GetGadgetText(#EditColor)
	RBG = Val("$" + String$)
	arr_rgb(2) = Red(RBG)
	arr_rgb(1) = Green(RBG)
	arr_rgb(0) = Blue(RBG)
	rgb_to_hsb()
	SetGadgetState(#Slider1 , arr_hsb(0))
	SetGadgetState(#Slider2 , arr_hsb(1))
	SetGadgetState(#Slider3 , arr_hsb(2))

	SetGadgetText(#Hue, Str(arr_hsb(0)))
	SetGadgetText(#Satur, Str(arr_hsb(1)))
	SetGadgetText(#Bright, Str(arr_hsb(2)))

	rgb_color = RGB(arr_rgb(0), arr_rgb(1), arr_rgb(2))
	SetGadgetColor(#Color, #PB_Gadget_BackColor, rgb_color)

	*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
	ScintillaMsg(*sciptr, #SCI_INDICSETFORE, num_item_color, rgb_color)
	; RBG = ScintillaMsg(*sciptr, #SCI_INDICGETFORE, num_item_color)	  ; получает цвет
EndProcedure

Procedure Events()
	Protected regex1$, n, txtLen, style
	Select Event()
		Case #PB_Event_Gadget
			Select EventGadget()

				Case #Slider1 ; ползунок
					arr_hsb(0) = GetGadgetState(#Slider1)
					Slider_Chande_Color()
					SetGadgetText(#Hue, Str(arr_hsb(0)))

				Case #Slider2 ; ползунок
					arr_hsb(1) = GetGadgetState(#Slider2)
					Slider_Chande_Color()
					SetGadgetText(#Hue, Str(arr_hsb(1)))

				Case #Slider3 ; ползунок
					arr_hsb(2) = GetGadgetState(#Slider3)
					Slider_Chande_Color()
					SetGadgetText(#Hue, Str(arr_hsb(2)))

				Case #Combo_Color ; Выбор цвета
					num_item_color = GetGadgetItemData(#Combo_Color , GetGadgetState(#Combo_Color))
					Set_Slider_Color_Sel_Ind()

				Case #ButtonApply ; Применить
					Set_Slider_Color_RGB()


				Case #Button_Color ; применить подсветку
					Highlight_All()

				Case #Button_Clear ; очистить подсветку
					*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
					txtLen = ScintillaMsg(*sciptr, #SCI_GETTEXTLENGTH)								  ; получает длину текста
					n = GetGadgetItemData(#Combo_Color , GetGadgetState(#Combo_Color))
					If n
						ScintillaMsg(*sciptr, #SCI_SETINDICATORCURRENT, n)	  ; делает индикатор под номером n текущим
						ScintillaMsg(*sciptr, #SCI_INDICATORCLEARRANGE, 0, txtLen)  ; до конца по длине текста, очистить всё
					EndIf

				Case #Button_ClearAll ; очистить подсветку
					*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
					txtLen = ScintillaMsg(*sciptr, #SCI_GETTEXTLENGTH)								  ; получает длину текста
					For n=3 To 18
						ScintillaMsg(*sciptr, #SCI_SETINDICATORCURRENT, n)	   ; делает индикатор под номером 7 текущим
						ScintillaMsg(*sciptr, #SCI_INDICATORCLEARRANGE, 0, txtLen)  ; до конца по длине текста, очистить всё
					Next

				Case #Button_RegEx ; может назвать apply? применить рег.выр.
					regex1$ = GetGadgetText(#Combo_RegEx)
					; RBG$ = GetGadgetText(#Combo_Color)
					; Item = GetGadgetState(#Combo_Color)
					If Len(regex1$)
						n = GetGadgetItemData(#Combo_Color , GetGadgetState(#Combo_Color))
						; MessageRequester("ассоциированное значение", Str(n))



						; От старого
						; ScintillaMsg(*sciptr, #SCI_SETLENGTHFORENCODE, -1)
						; regex1$ = PeekS(*MemID_res, -1, #PB_Ascii)            ; Считываем значение из области памяти
						; Попытка конвертировать текст поиска в кодировку документа, пока не помогло

						*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
						If ScintillaMsg(*sciptr, #SCI_GETCODEPAGE) = 0
							*MemoireID = UTF8(regex1$)
							If *MemoireID ; Если указатель получен, то
								*MemID_res = AllocateMemory(5000) ; Выделяем память на 5000 символов
								If *MemID_res					  ; Если указатель получен, то
									ScintillaMsg(*sciptr, #SCI_ENCODEDFROMUTF8, *MemoireID, *MemID_res)
									regex1$ = PeekS(*MemID_res) ; Считываем значение из области памяти
									FreeMemory(*MemID_res)
								EndIf
								FreeMemory(*MemoireID)
							EndIf
							Color(@regex1$, Len(regex1$), n)

							; Попытка конвертировать текст поиска в UTF-8, на самом деле он и так в UTF-8, а кроме этого есть функция UTF8(regex1$)
						ElseIf ScintillaMsg(*sciptr, #SCI_GETCODEPAGE) = 65001
							; MessageRequester("Кодировка", Str(ScintillaMsg(*sciptr, #SCI_GETCODEPAGE)))
							; MakeUTF8Text(regex1$)
							Color(MakeScintillaText(regex1$, @regexLength), @regexLength, n)
						EndIf

						; MessageRequester("Сообщение", regex1$ + #CRLF$ + Str(Len(regex1$)))

						; zz =  Len(regex1$)
						; Color(@regex1$, @zz, n)
						; Color(@regex1$, Len(regex1$), n)
					EndIf

				Case #Button_ini1 ; Открыть ini-файл
					RunProgram(PathConfig$ + "\Highlight.ini")

				Case #Button_ini2 ; Открыть ini-файл
					RunProgram(PathConfig$ + "\Highlight_Sample.ini")

				Case #Combo_Indic ; Выбор индикатора
					*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
																									  ; MessageRequester("Индекс", Str(GetGadgetState(#Combo_Indic)))
																									  ; style = GetGadgetItemData(#Combo_Indic , GetGadgetState(#Combo_Indic))
					style =GetGadgetState(#Combo_Indic)
					Count = CountGadgetItems(#Combo_Color)
					; MessageRequester("Данные", "Count " + Str(Count) + #CRLF$ + "style " + Str(style))
					For i=0 To Count - 1
						num = GetGadgetItemData(#Combo_Color , i)
						ScintillaMsg(*sciptr, #SCI_INDICSETSTYLE, num, style)
					Next

			EndSelect
		Case #PB_Event_CloseWindow
			; перед закрытием отсоединяем события
			UnbindEvent(#PB_Event_Gadget, @Events(), #Window_0)
			UnbindEvent(#PB_Event_CloseWindow, @Events(), #Window_0)
			CloseWindow(#Window_0)
	EndSelect
EndProcedure

; проверка, что строка представлена в виде шестнадцатеричного числа
Procedure isHexStr(Hex$, islen=0)
	If islen And Not Len(Hex$)=islen : ProcedureReturn 0 : EndIf
	For i=48 To 57
		; ReplaceString(Hex$,  Chr(i) , "Z", 2, 1)
		Hex$ = RemoveString(Hex$ , Chr(i))
	Next
	For i=65 To 70
		; ReplaceString(Hex$,  Chr(i) , "Z", 2, 1) ; нужно ещё нижний регистр
		Hex$ = RemoveString(Hex$ , Chr(i), #PB_String_NoCase)
	Next
	If Hex$=""
		ProcedureReturn 1
	Else
		ProcedureReturn 0
	EndIf
EndProcedure

; проверка, что строка представлена в виде шестнадцатеричного числа
Procedure isNumStr(Num$, islen=0)
	For i=48 To 57
		; ReplaceString(Num$,  Chr(i) , "Z", 2, 1)
		Num$ = RemoveString(Num$ , Chr(i))
	Next
	If Num$=""
		ProcedureReturn 1
	Else
		ProcedureReturn 0
	EndIf
EndProcedure

Procedure Menu()
	If IsWindow(#Window_0)=0 ; если окно не найдено, то

		*sciptr = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTPOINTER, 0, 0) ; хендл окна scintilla
		; Показать какие стили зарегистрированы, чтобы не трогать их
		; ttt$=""
		; For i=0 To 35
		; ttt$ + #CRLF$ + Str(i) + #TAB$ + Str(ScintillaMsg(*sciptr, #SCI_INDICGETSTYLE, i)) + #TAB$ + Hex(ScintillaMsg(*sciptr, #SCI_INDICGETFORE, i))
		; Next
		; MessageRequester("Стили", ttt$)

		OpenWindow_0()		 ; Создаём окно
							 ; биндим элементы окна (вешаем события)
		BindEvent(#PB_Event_Gadget, @Events(), #Window_0)
		BindEvent(#PB_Event_CloseWindow, @Events(), #Window_0)

		; Добавление палитры в комбо
		Protected Color1.l, n=0, num=3, RBG$, img_id, img, KeyNum, KeyName$
		If OpenPreferences(PathConfig$ + "\Highlight.ini") ; открываем ini
			If PreferenceGroup("Palette")				   ; выбираем группу (секцию)
				ExaminePreferenceKeys()
				While NextPreferenceKey()
					RBG$ = PreferenceKeyName()
					If Not isHexStr(RBG$, 6):Continue:EndIf ; проверка что имя ключа является шестнадцатеричным числом длиной 6 символов
					Color1 = Val("$" + Mid(RBG$, 5, 2)+Mid(RBG$, 3, 2)+Mid(RBG$, 1, 2)) ; конвертирует RBG в BGR и преобразует в число
					img_id = CreateImage(#PB_Any, 16, 16, 24, Color1)
					If img_id
						img = ImageID(img_id)
					Else
						img = 0
					EndIf
					AddGadgetItem(#Combo_Color, -1 , RBG$ + "   (" + Str(num) + ")", img) ; Добавляем элемент в комобо
					SetGadgetItemData(#Combo_Color , n , num)							  ; к индексу привязываем значение палитры, чтобы выбирать связанный цвет
																						  ; Создание индикаторов
					ScintillaMsg(*sciptr, #SCI_INDICSETSTYLE, num, 17)					  ; #INDIC_TEXTFORE = 17 создат индикатор под номером 7 (занятые по уиолчанию 0, 1, 2)
					ScintillaMsg(*sciptr, #SCI_INDICSETFORE, num, Color1)				  ; назначает цвет индикатора под номером 7 - зелёный
					n+1
					num+1
				Wend
				SetGadgetState(#Combo_Color, 0)
				; Set_Slider_Color()
			EndIf
			; ClosePreferences() ; не закрываем потому что до кучи обрабатываем следующую секцию
			; EndIf

			; Добавление регвыров в комбо, будет потом история
			n=0
			; If OpenPreferences(PathConfig$ + "\Highlight.ini") ; открываем ini (ранее открыли)
			If PreferenceGroup("color_regexp")											; выбираем группу (секцию)
				ExaminePreferenceKeys()
				While NextPreferenceKey()
					KeyName$ = PreferenceKeyName()
					KeyNum = Val(KeyName$)
					If Not isNumStr(KeyName$) Or KeyNum<0 Or KeyNum>35: Continue:EndIf ; проверка что имя ключа является числом от 0 до 35
					AddGadgetItem(#Combo_RegEx, -1 , PreferenceKeyValue())			   ; Добавляем элемент в комобо

					; Конвертируем в UTF-8 (не требуется, конфиги и так в нём)
					; KeyName$ = PreferenceKeyValue()
					; MakeUTF8Text(KeyName$)
					; AddGadgetItem(#Combo_RegEx, -1 , KeyName$) ; Добавляем элемент в комобо

					SetGadgetItemData(#Combo_RegEx , n , KeyNum) ; к индексу привязываем значение палитры, чтобы выбирать связанный цвет
					n+1
				Wend
				SetGadgetState(#Combo_RegEx, 0)
			EndIf
			ClosePreferences()
		EndIf

		; Добавление синтаксисов в комбо
		n=0
		If OpenPreferences(PathConfig$ + "\Highlight_Sample.ini") ; открываем ini
			If ExaminePreferenceGroups()
				While NextPreferenceGroup() ; Пока находит группы
					AddGadgetItem(#Combo_Sample, -1 , PreferenceGroupName()) ; Добавляем элемент в комобо
				Wend
				SetGadgetState(#Combo_Sample, 0)
			EndIf
			ClosePreferences()
		EndIf

		For i=0 To 20
			AddGadgetItem(#Combo_Indic, -1 , Str(i)) ; Добавляем элемент в комобо
			 ; SetGadgetItemData(#Combo_Indic , i , i) ; к индексу привязываем значение, чтобы выбирать связанный индикатор
		Next
		SetGadgetState(#Combo_Indic, 17)
		Set_Slider_Color_Sel_Ind()
		Slider_Chande_Color()

		; Спектр
		If StartDrawing(CanvasOutput(#Spectr))
			Protected w, h
			w=OutputWidth()
			h=OutputHeight()
			arr_hsb(1) = 100
			arr_hsb(2) = 100

			For i=0 To w
				arr_hsb(0)=i*360/w
				hsb_to_rgb()
				Line(i, 1, 1, h, RGB(arr_rgb(0), arr_rgb(1), arr_rgb(2)))
			Next

			StopDrawing()
		EndIf

		arr_hsb(0) = GetGadgetState(#Slider1)
		arr_hsb(1) = GetGadgetState(#Slider2)
		arr_hsb(2) = GetGadgetState(#Slider3)
		SetGadgetText(#Hue, Str(arr_hsb(0)))
		SetGadgetText(#Satur, Str(arr_hsb(1)))
		SetGadgetText(#Bright, Str(arr_hsb(2)))
	Else
		SetWindowState(#Window_0, #PB_Window_Normal)
		SetActiveWindow(#Window_0)
	EndIf
EndProcedure

DataSection
	Highlight_ini:
	IncludeBinary "Highlight.ini"
	Highlight_iniend:

	Highlight_Sample_ini:
	IncludeBinary "Highlight_Sample.ini"
	Highlight_Sample_iniend:
EndDataSection

; ExecutableFormat = Shared dll
; FirstLine = 789
; Folding = -----
; EnableOnError
; Executable = Highlight.dll
