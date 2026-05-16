using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.IO;
using System.Threading;

public class TalkItBridge {
    [DllImport("TIBASE32.DLL", EntryPoint="_SVOpenSpeech@20", CallingConvention=CallingConvention.StdCall)]
    public static extern uint SVOpenSpeech(out IntPtr phSpeech, IntPtr hwndOwner, uint deviceId, uint languageFlags, uint reserved);

    [DllImport("TIBASE32.DLL", EntryPoint="_SVCloseSpeech@4", CallingConvention=CallingConvention.StdCall)]
    public static extern uint SVCloseSpeech(IntPtr hSpeech);

    [DllImport("TIBASE32.DLL", EntryPoint="_SVNarrate@20", CallingConvention=CallingConvention.StdCall)]
    public static extern uint SVNarrate(IntPtr hSpeech, string text, IntPtr hwndNotify, uint flags, uint reserved);

    [DllImport("TIBASE32.DLL", EntryPoint="_SVSetPersonality@8", CallingConvention=CallingConvention.StdCall)]
    public static extern uint SVSetPersonality(IntPtr hSpeech, uint personality);

    [DllImport("TIBASE32.DLL", EntryPoint="_SVSetRate@8", CallingConvention=CallingConvention.StdCall)]
    public static extern uint SVSetRate(IntPtr hSpeech, uint rate);

    [DllImport("TIBASE32.DLL", EntryPoint="_SVSetPitch@8", CallingConvention=CallingConvention.StdCall)]
    public static extern uint SVSetPitch(IntPtr hSpeech, uint pitch);

    [DllImport("user32.dll")]
    public static extern uint RegisterWindowMessage(string lpString);

    private static uint SVSyncMessages;
    private static IntPtr hSpeech = IntPtr.Zero;
    private static bool done = false;
    private static string logPath;

    static void Log(string msg) {
        try { File.AppendAllText(logPath, DateTime.Now.ToString("HH:mm:ss") + ": " + msg + Environment.NewLine); } catch {}
    }

    class MessageHandler : NativeWindow {
        public MessageHandler() {
            CreateHandle(new CreateParams());
        }
        protected override void WndProc(ref Message m) {
            if (m.Msg == SVSyncMessages) {
                if (m.WParam.ToInt32() == 0x3E9) {
                    done = true;
                }
            }
            base.WndProc(ref m);
        }
    }

    [STAThread]
    public static void Main(string[] args) {
        logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "bridge_log.txt");
        Log("Bridge started (Test version). Args: " + string.Join(" ", args));

        if (args.Length < 1) return;
        
        string text = args[0];
        if (File.Exists(text)) text = File.ReadAllText(text);

        uint voice = args.Length > 1 ? uint.Parse(args[1]) : 0;
        uint rate = args.Length > 2 ? uint.Parse(args[2]) : 150;
        uint pitch = args.Length > 3 ? uint.Parse(args[3]) : 100;

        SVSyncMessages = RegisterWindowMessage("SVSyncMessages");
        MessageHandler mh = new MessageHandler();

        uint res = SVOpenSpeech(out hSpeech, mh.Handle, 0xFFFFFFFF, 1, 0);
        Log("Open result: " + res + " Handle: " + hSpeech);

        if (res == 0 && hSpeech != IntPtr.Zero) {
            SVSetPersonality(hSpeech, voice);
            SVSetRate(hSpeech, rate);
            SVSetPitch(hSpeech, pitch);

            uint narrateRes = SVNarrate(hSpeech, text, mh.Handle, 0, 0);
            Log("Narrate result: " + narrateRes);

            if (narrateRes == 0) {
                DateTime end = DateTime.Now.AddSeconds(10);
                while (DateTime.Now < end && !done) {
                    Application.DoEvents();
                    Thread.Sleep(50);
                }
            }
            SVCloseSpeech(hSpeech);
        }
        Log("Bridge exiting.");
    }
}
