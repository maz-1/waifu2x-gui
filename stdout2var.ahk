StdOutStream( sCmd, Callback = "", WorkingDir=0) { ; Modified  :  maz-1 https://gist.github.com/maz-1/768bf7938e533907d54bff276db80904
  Static StrGet := "StrGet"           ; Modified  :  SKAN 31-Aug-2013 http://goo.gl/j8XJXY
                                      ; Thanks to :  HotKeyIt         http://goo.gl/IsH1zs
                                      ; Original  :  Sean 20-Feb-2007 http://goo.gl/mxCdn
  tcWrk := WorkingDir=0 ? "Int" : "Str"
  DllCall( "CreatePipe", UIntP,hPipeRead, UIntP,hPipeWrite, UInt,0, UInt,0 )
  DllCall( "SetHandleInformation", UInt,hPipeWrite, UInt,1, UInt,1 )
  If A_PtrSize = 8
  {
    VarSetCapacity( STARTUPINFO, 104, 0  )      ; STARTUPINFO          ;  http://goo.gl/fZf24
    NumPut( 68,         STARTUPINFO,  0 )      ; cbSize
    NumPut( 0x100,      STARTUPINFO, 60 )      ; dwFlags    =>  STARTF_USESTDHANDLES = 0x100
    NumPut( hPipeWrite, STARTUPINFO, 88 )      ; hStdOutput
    NumPut( hPipeWrite, STARTUPINFO, 96 )      ; hStdError
    VarSetCapacity( PROCESS_INFORMATION, 24 )  ; PROCESS_INFORMATION  ;  http://goo.gl/b9BaI
  }
  Else
  {
    VarSetCapacity( STARTUPINFO, 68, 0  )
    NumPut( 68,         STARTUPINFO,  0 )
    NumPut( 0x100,      STARTUPINFO, 44 )
    NumPut( hPipeWrite, STARTUPINFO, 60 )
    NumPut( hPipeWrite, STARTUPINFO, 64 )
    VarSetCapacity( PROCESS_INFORMATION, 16 )
  }
  ;Tip for struct calculation
  ;======================================
  ; x64
  ; STARTUPINFO
  ;                             offset    size                    comment
  ;DWORD  cb;                   0         4
  ;LPTSTR lpReserved;           8         8(A_PtrSize)            aligned to 8-byte boundary (4 + 4)
  ;LPTSTR lpDesktop;            16        8(A_PtrSize)
  ;LPTSTR lpTitle;              24        8(A_PtrSize)
  ;DWORD  dwX;                  32        4
  ;DWORD  dwY;                  36        4
  ;DWORD  dwXSize;              40        4
  ;DWORD  dwYSize;              44        4
  ;DWORD  dwXCountChars;        48        4
  ;DWORD  dwYCountChars;        52        4
  ;DWORD  dwFillAttribute;      56        4
  ;DWORD  dwFlags;              60        4
  ;WORD   wShowWindow;          64        2
  ;WORD   cbReserved2;          66        2
  ;LPBYTE lpReserved2;          72        8(A_PtrSize)           aligned to 8-byte boundary (2 + 4)
  ;HANDLE hStdInput;            80        8(A_PtrSize) 
  ;HANDLE hStdOutput;           88        8(A_PtrSize) 
  ;HANDLE hStdError;            96        8(A_PtrSize) 
  ;
  ;ALL : 96+8=104=8*13
  ;
  ; PROCESS_INFORMATION
  ;
  ;HANDLE hProcess              0         8(A_PtrSize)
  ;HANDLE hThread               8         8(A_PtrSize)
  ;DWORD  dwProcessId           16        4
  ;DWORD  dwThreadId            20        4
  ;
  ;ALL : 20+4=24=8*3
  ;======================================
  ; x86
  ; STARTUPINFO
  ;                             offset     size
  ;DWORD  cb;                   0          4
  ;LPTSTR lpReserved;           4          4(A_PtrSize)            
  ;LPTSTR lpDesktop;            8          4(A_PtrSize)
  ;LPTSTR lpTitle;              12         4(A_PtrSize)
  ;DWORD  dwX;                  16         4
  ;DWORD  dwY;                  20         4
  ;DWORD  dwXSize;              24         4
  ;DWORD  dwYSize;              28         4
  ;DWORD  dwXCountChars;        32         4
  ;DWORD  dwYCountChars;        36         4
  ;DWORD  dwFillAttribute;      40         4
  ;DWORD  dwFlags;              44         4
  ;WORD   wShowWindow;          48         2
  ;WORD   cbReserved2;          50         2
  ;LPBYTE lpReserved2;          52         4(A_PtrSize)           
  ;HANDLE hStdInput;            56         4(A_PtrSize) 
  ;HANDLE hStdOutput;           60         4(A_PtrSize) 
  ;HANDLE hStdError;            64         4(A_PtrSize) 
  ;
  ;ALL : 64+4=68=4*17
  ;
  ; PROCESS_INFORMATION
  ;
  ;HANDLE hProcess              0         4(A_PtrSize)
  ;HANDLE hThread               4         4(A_PtrSize)
  ;DWORD  dwProcessId           8        4
  ;DWORD  dwThreadId            12        4
  ;
  ;ALL : 12+4=16=4*4
  
  If ! DllCall( "CreateProcess", UInt,0, UInt,&sCmd, UInt,0, UInt,0 ;  http://goo.gl/USC5a
              , UInt,1, UInt,0x08000000, UInt,0, tcWrk, WorkingDir
              , UInt,&STARTUPINFO, UInt,&PROCESS_INFORMATION ) 
   Return "" 
   , DllCall( "CloseHandle", UInt,hPipeWrite ) 
   , DllCall( "CloseHandle", UInt,hPipeRead )
   , DllCall( "SetLastError", Int,-1 )     

  hProcess := NumGet( PROCESS_INFORMATION, 0 )                 
  hThread  := NumGet( PROCESS_INFORMATION, A_PtrSize )  

  DllCall( "CloseHandle", UInt,hPipeWrite )

  AIC := ( SubStr( A_AhkVersion, 1, 3 ) = "1.0" ) ;  A_IsClassic 
  VarSetCapacity( Buffer, 4096, 0 ), nSz := 0 
  
  While DllCall( "ReadFile", UInt,hPipeRead, UInt,&Buffer, UInt,4094, UIntP,nSz, Int,0 ) {

   tOutput := ( AIC && NumPut( 0, Buffer, nSz, "Char" ) && VarSetCapacity( Buffer,-1 ) ) 
              ? Buffer : %StrGet%( &Buffer, nSz, "CP0" ) ; formerly CP850, but I guess CP0 is suitable for different locales

   Isfunc( Callback ) ? %Callback%( tOutput, A_Index ) : sOutput .= tOutput

  }                   
 
  DllCall( "GetExitCodeProcess", UInt,hProcess, UIntP,ExitCode )
  DllCall( "CloseHandle",  UInt,hProcess  )
  DllCall( "CloseHandle",  UInt,hThread   )
  DllCall( "CloseHandle",  UInt,hPipeRead )
  DllCall( "SetLastError", UInt,ExitCode  )
  VarSetCapacity(STARTUPINFO, 0)
  VarSetCapacity(PROCESS_INFORMATION, 0)

Return Isfunc( Callback ) ? %Callback%( "", 0 ) : sOutput      
}
