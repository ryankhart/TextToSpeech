﻿using Microsoft.DirectX.DirectSound;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;

namespace JocysCom.WoW.TextToSpeech.Audio
{
    public class EffectsPreset
    {

        public string Name { get; set; }
        static string _fileSufix = ".preset.xml";

        //public static Guid[] effects = new Guid[] {
        //    DSoundHelper.StandardChorusGuid,
        //    DSoundHelper.StandardCompressorGuid,
        //    DSoundHelper.StandardDistortionGuid,
        //    DSoundHelper.StandardEchoGuid,
        //    DSoundHelper.StandardFlangerGuid,
        //    DSoundHelper.StandardGargleGuid,
        //    DSoundHelper.StandardInteractive3DLevel2ReverbGuid,
        //    DSoundHelper.StandardParamEqGuid,
        //    DSoundHelper.StandardWavesReverbGuid,
        //};

        public static BindingList<EffectsPreset> GetPresets()
        {
            var dir = new System.IO.DirectoryInfo(".");
            var presetNames = dir.GetFiles("*" + _fileSufix, System.IO.SearchOption.AllDirectories)
                .Select(x => x.Name.Replace(_fileSufix, ""))
                .Distinct()
                .OrderBy(x=>x);
            var list = new BindingList<EffectsPreset>();
            foreach (var name in presetNames)
            {
                var preset = LoadPreset(name);
                list.Add(preset);
            }
            // move default to the top.
            var def = list.FirstOrDefault(x => x.Name == "Default");
            // Create if not exists.
            if (def == null)
            {
                def = new EffectsPreset();
                def.Name = "Default";
                SavePreset(def);
            }
            else
            {
                list.Remove(def);
            }
            list.Insert(0, def);
            return list;
        }

        public static void SavePreset(EffectsPreset preset)
        {
            var fileName = preset.Name + _fileSufix;
            var dir = new System.IO.DirectoryInfo(".");
            var presetsDir = new System.IO.DirectoryInfo("Presets");
            if (!presetsDir.Exists) presetsDir = dir;
            var file = dir.GetFiles(fileName, System.IO.SearchOption.AllDirectories).FirstOrDefault();
            // if file doesn't exist anywhere then...
            if (file == null)
            {
                var path = System.IO.Path.Combine(presetsDir.FullName, fileName);
                file = new System.IO.FileInfo(path);
            }
            var xml = MainHelper.SerializeToXmlString(preset);
            System.IO.File.WriteAllText(file.FullName, xml, System.Text.Encoding.UTF8);
        }

        public static EffectsPreset LoadPreset(string name)
        {
            var dir = new System.IO.DirectoryInfo(".");
            var fi = dir.GetFiles(name + _fileSufix, System.IO.SearchOption.AllDirectories).FirstOrDefault();
            if (fi == null) return null;
            var xml = System.IO.File.ReadAllText(fi.FullName, System.Text.Encoding.UTF8);
            var preset = MainHelper.DeserializeFromXmlString<EffectsPreset>(xml);
            return preset;
        }

        public static EffectsPreset NewPreset()
        {
            var i = 1;
            var dir = new System.IO.DirectoryInfo(".");
            // Find unused name;
            while (true)
            {
                var name = string.Format("NewPrest{0}", i);
                var fi = dir.GetFiles(name + _fileSufix, System.IO.SearchOption.AllDirectories).FirstOrDefault();
                if (fi == null)
                {
                    var preset = new EffectsPreset();
                    preset.Name = name;
                    SavePreset(preset);
                    return preset;
                }
                i++;
            }
        }

        public EffectsPreset()
        {
            Chorus = new EffectsChorus();
        }

        public bool GeneralEnabled { get; set; }
        public bool ChorusEnabled { get; set; }
        public bool CompressorEnabled { get; set; }
        public bool DistortionEnabled { get; set; }
        public bool EchoEnabled { get; set; }
        public bool FlangerEnabled { get; set; }
        public bool GargleEnabled { get; set; }
        public bool ParamEqEnabled { get; set; }
        public bool ReverbEnabled { get; set; }
        public bool Reverb3DEnabled { get; set; }

        public EffectsGeneral General { get; set; }
        public EffectsChorus Chorus { get; set; }
        public EffectsCompressor Compressor { get; set; }
        public EffectsDistortion Distortion { get; set; }
        public EffectsEcho Echo { get; set; }
        public EffectsFlanger Flanger { get; set; }
        public EffectsGargle Gargle { get; set; }
        public EffectsParamEq ParamEq { get; set; }
        public EffectsWavesReverb Reverb { get; set; }
        public EffectsInteractive3DLevel2Reverb Reverb3D { get; set; }

    }
}
