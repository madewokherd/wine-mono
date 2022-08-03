using System;
using System.Runtime.InteropServices;

internal static partial class Interop {
	internal static partial class WinMM {
		const string WINMM = "winmm";

		public const uint CALLBACK_FUNCTION = 0x30000;

		public const int MAXPNAMELEN = 32;

		public enum MM_MSG : int {
			MM_WOM_OPEN=0x3bb,
			MM_WOM_CLOSE=0x3bc,
			MM_WOM_DONE=0x3bd,
		}

		[StructLayout(LayoutKind.Sequential)]
		public struct WAVEHDR {
			public IntPtr lpData;
			public uint dwBufferLength;
			public uint dwBytesRecorded;
			public IntPtr dwUser;
			public uint dwFlags;
			public uint dwLoops;
			public IntPtr lpNext;
			public IntPtr reserved;
		}

		[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
		public struct WAVEOUTCAPS {
			public short wMid;
			public short wPid;
			public short vDriverVersion;
			[MarshalAs(UnmanagedType.ByValTStr, SizeConst=MAXPNAMELEN)] public string szPname;
			public int dwFormats;
			public short wChannels;
			public short wReserved1;
			public int dwSupport;
		}

		[UnmanagedFunctionPointer(CallingConvention.StdCall)]
		public delegate void WaveOutProc(IntPtr hwo, MM_MSG uMsg, IntPtr dwInstance, IntPtr dwParam1, IntPtr dwParam2);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static MMSYSERR waveOutClose(IntPtr hwo);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall, CharSet=CharSet.Unicode, EntryPoint="waveOutGetDevCapsW")]
		public extern static MMSYSERR waveOutGetDevCaps(IntPtr uDeviceID, ref WAVEOUTCAPS caps, int cbwoc);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static int waveOutGetNumDevs();

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static MMSYSERR waveOutOpen(ref IntPtr hwo, int uDeviceID,
			[MarshalAs(UnmanagedType.LPArray)] byte[] pwfx, WaveOutProc dwCallback, IntPtr dwInstance, uint fdwOpen);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static MMSYSERR waveOutPause(IntPtr hwo);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static MMSYSERR waveOutPrepareHeader(IntPtr hwo, IntPtr pwh, int cbwh);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static MMSYSERR waveOutReset(IntPtr hwo);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static MMSYSERR waveOutRestart(IntPtr hwo);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static MMSYSERR waveOutUnprepareHeader(IntPtr hwo, IntPtr pwh, int cbwh);

		[DllImport(WINMM, CallingConvention=CallingConvention.StdCall)]
		public extern static MMSYSERR waveOutWrite(IntPtr hwo, IntPtr pwh, int cbwh);
	}
}
