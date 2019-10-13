﻿using Amazon;
using Amazon.Polly;
using Amazon.Polly.Model;
using JocysCom.ClassLibrary.Controls;
using JocysCom.TextToSpeech.Monitor.Audio;
using JocysCom.TextToSpeech.Monitor.Voices;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;

namespace JocysCom.TextToSpeech.Monitor.Controls
{
	public partial class VoicesUserControl : UserControl
	{
		public VoicesUserControl()
		{
			InitializeComponent();
			if (ControlsHelper.IsDesignMode(this))
				return;
			StatusPanel.Visible = false;
			VoicesDataGridView.AutoGenerateColumns = false;
			// Enable double buffering to make redraw faster.
			typeof(DataGridView).InvokeMember("DoubleBuffered",
			BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.SetProperty,
			null, VoicesDataGridView, new object[] { true });
		}

		public DataGridView VoicesGridView
		{
			get { return VoicesDataGridView; }
		}

		public void EnableGrid(bool enabled)
		{
			VoicesDataGridView.Enabled = enabled;
			VoicesDataGridView.DefaultCellStyle.SelectionBackColor = enabled
				? SystemColors.Highlight
				: SystemColors.ControlDark;
		}

		public InstalledVoiceEx GetSelectedItem()
		{
			var selectedItem = VoicesGridView.SelectedRows.Cast<DataGridViewRow>().FirstOrDefault();
			if (selectedItem != null)
				return (InstalledVoiceEx)selectedItem.DataBoundItem;
			return null;
		}

		public void SelectItem(InstalledVoiceEx item)
		{
			foreach (DataGridViewRow row in VoicesDataGridView.Rows)
			{
				if (!row.DataBoundItem.Equals(item))
					continue;
				row.Selected = true;
				VoicesDataGridView.FirstDisplayedCell = row.Cells[0];
				break;
			}
		}

		#region Appearance

		/// <summary>
		/// Gets or sets the object used to marshal event-handler calls that are issued when
		/// an interval has elapsed.
		/// </summary>
		[Category("Appearance"), Browsable(true), DefaultValue(true)]
		public bool MenuButtonsVisible { get { return VoicesToolStrip.Visible; } set { VoicesToolStrip.Visible = value; } }

		/// <summary>
		/// Gets or sets the object used to marshal event-handler calls that are issued when
		/// an interval has elapsed.
		/// </summary>
		[Category("Appearance"), Browsable(true), DefaultValue(true)]
		public bool GenderRatesVisible
		{
			get
			{
				return
					MaleColumn.Visible &
					FemaleColumn.Visible &
					NeutralColumn.Visible;
			}
			set
			{
				MaleColumn.Visible = value;
				FemaleColumn.Visible = value;
				NeutralColumn.Visible = value;
			}
		}

		#endregion

		#region VoicesDataGridView

		private void VoicesDataGridView_DataError(object sender, DataGridViewDataErrorEventArgs e)
		{
			//if (e.RowIndex == -1) return;
			//var grid = (DataGridView)sender;
			//var voice = (InstalledVoiceEx)grid.Rows[e.RowIndex].DataBoundItem;
			//var column = VoicesDataGridView.Columns[e.ColumnIndex];
			e.Cancel = true;
		}

		private void VoicesDataGridView_CellFormatting(object sender, DataGridViewCellFormattingEventArgs e)
		{
			if (e.RowIndex == -1) return;
			var grid = (DataGridView)sender;
			var voice = (InstalledVoiceEx)grid.Rows[e.RowIndex].DataBoundItem;
			var column = VoicesDataGridView.Columns[e.ColumnIndex];
			if (e.ColumnIndex == grid.Columns[AgeColumn.Name].Index)
			{
				if (voice.Age.ToString() == "NotSet") e.Value = "...";
			}
			e.CellStyle.ForeColor = voice.Enabled
				? VoicesDataGridView.DefaultCellStyle.ForeColor
				: SystemColors.ControlDark;
			e.CellStyle.SelectionBackColor = voice.Enabled
			 ? VoicesDataGridView.DefaultCellStyle.SelectionBackColor
			 : SystemColors.ControlDark;
		}

		private void VoicesDataGridView_CellClick(object sender, DataGridViewCellEventArgs e)
		{
			if (e.RowIndex < 0) return;
			var grid = (DataGridView)sender;
			//var column = VoicesDataGridView.Columns[e.ColumnIndex];
			if (e.ColumnIndex == grid.Columns[EnabledColumn.Name].Index)
			{
				var voice = (InstalledVoiceEx)grid.Rows[e.RowIndex].DataBoundItem;
				voice.Enabled = !voice.Enabled;
				VoicesDataGridView.Invalidate();
			}
			if (e.ColumnIndex == grid.Columns[FemaleColumn.Name].Index) VoicesDataGridView.BeginEdit(true);
			if (e.ColumnIndex == grid.Columns[MaleColumn.Name].Index) VoicesDataGridView.BeginEdit(true);
			if (e.ColumnIndex == grid.Columns[NeutralColumn.Name].Index) VoicesDataGridView.BeginEdit(true);
		}


		#endregion

		private void AddLocalVoicesButton_Click(object sender, System.EventArgs e)
		{
			var form = new AddVoicesForm();
			form.Text = string.Format("{0} {1}: Local Voices", Application.CompanyName, Application.ProductName);
			form.StartPosition = FormStartPosition.CenterParent;
			if (Global.LocalVoices == null)
				Global.LocalVoices = new BindingList<InstalledVoiceEx>();
			form.VoicesGridView.DataSource = Global.LocalVoices;
			var result = form.ShowDialog();
			if (result == DialogResult.OK)
			{
			}
			form.VoicesGridView.DataSource = null;
		}

		private void AddAmazonNeuralVoicesButton_Click(object sender, System.EventArgs e)
		{
			var form = new AddVoicesForm();
			form.Text = string.Format("{0} {1}: Amazon Neural Voices", Application.CompanyName, Application.ProductName);
			form.StartPosition = FormStartPosition.CenterParent;
			if (Global.AmazonNeuralVoices == null)
				Global.AmazonNeuralVoices = new BindingList<InstalledVoiceEx>();
			form.VoicesGridView.DataSource = Global.AmazonNeuralVoices;
			var result = form.ShowDialog();
			if (result == DialogResult.OK)
			{
			}
			form.VoicesGridView.DataSource = null;
		}

		private void AddAmazonStandardVoicesButton_Click(object sender, System.EventArgs e)
		{
			var form = new AddVoicesForm();
			form.Text = string.Format("{0} {1}: Amazon Standard Voices", Application.CompanyName, Application.ProductName);
			form.StartPosition = FormStartPosition.CenterParent;
			if (Global.AmazonStandardVoices == null)
				Global.AmazonStandardVoices = new BindingList<InstalledVoiceEx>();
			form.VoicesGridView.DataSource = Global.AmazonStandardVoices;
			var result = form.ShowDialog();
			if (result == DialogResult.OK)
			{
			}
			form.VoicesGridView.DataSource = null;
		}

		public void RefreshVoices(bool force = false)
		{
			if (VoicesGridView.DataSource == Global.LocalVoices && (Global.LocalVoices.Count == 0 || force))
				RefreshLocalVoices(Global.LocalVoices);
			if (VoicesGridView.DataSource == Global.AmazonNeuralVoices && (Global.AmazonNeuralVoices.Count == 0 || force))
				RefreshAmazonVoices(Engine.Neural, Global.AmazonNeuralVoices);
			if (VoicesGridView.DataSource == Global.AmazonStandardVoices && (Global.AmazonStandardVoices.Count == 0 || force))
				RefreshAmazonVoices(Engine.Standard, Global.AmazonStandardVoices);
		}

		void RefreshLocalVoices(BindingList<InstalledVoiceEx> list)
		{
			// Start refreshing voices.
			ControlsHelper.BeginInvoke(() =>
			{
				list.Clear();
				var voices = Voices.VoiceHelper.GetLocalVoices();
				foreach (var voice in voices)
					list.Add(voice);
			});
		}

		Thread _Thread;
		bool _CancelGetVoices;

		void RefreshAmazonVoices(Engine engine, BindingList<InstalledVoiceEx> list)
		{
			_CancelGetVoices = false;
			StatusPanel.Visible = true;
			list.Clear();
			var voices = new List<InstalledVoiceEx>();
			var ts = new System.Threading.ThreadStart(delegate ()
			{
				voices = GetAmazonVoices(null, engine, null);
				ControlsHelper.Invoke(() =>
				{
					foreach (var voice in voices)
						list.Add(voice);
				});
			});
			_Thread = new Thread(ts);
			_Thread.Start();
		}

		public List<InstalledVoiceEx> GetAmazonVoices(RegionEndpoint region = null, Engine engine = null, CultureInfo culture = null)
		{
			ControlsHelper.Invoke(() =>
			{
				StatusLabel.Text = "Please Wait...\r\n";
			});
			var list = new List<InstalledVoiceEx>();
			var tempList = new List<InstalledVoiceEx>();
			// Get regions to process.
			var regions = region == null
				? RegionEndpoint.EnumerableAllRegions.OrderBy(x => x.ToString()).ToList()
				: new List<RegionEndpoint>() { region };
			for (int i = 0; i < regions.Count; i++)
			{
				var r = regions[i];
				AmazonPolly client = null;
				try
				{
					client = new AmazonPolly(
						SettingsManager.Options.AmazonAccessKey,
						SettingsManager.Options.AmazonSecretKey,
						r.SystemName
					);
				}
				catch (Exception ex)
				{
					Console.WriteLine(ex);
					continue;
				}
				var request = new DescribeVoicesRequest();
				if (engine != null)
					request.Engine = engine;
				if (culture != null)
					request.LanguageCode = culture.Name;
				ControlsHelper.Invoke(() =>
				{
					StatusLabel.Text += string.Format("{0}/{1} - Region={2}, Engine={3}, Culture={4}",
					i + 1, regions.Count, r.DisplayName, request.Engine, request.LanguageCode);
					Application.DoEvents();
				});
				// Create stop watch to measure speed with the servers.
				var sw = new Stopwatch();
				var voices = client.GetVoices(request, 5000);
				var elapsed = sw.Elapsed;
				ControlsHelper.Invoke(() =>
				{
					StatusLabel.Text += string.Format(", Voices={0}", voices.Count);
					if (client.LastException != null)
						StatusLabel.Text += string.Format(", Exception={0}", client.LastException.Message);
				});
				var vex = 0;
				for (int v = 0; v < voices.Count; v++)
				{
					var voice = voices[i];
					var cultureNames = new List<string>();
					cultureNames.Add(voice.LanguageCode);
					cultureNames.AddRange(voice.AdditionalLanguageCodes);
					// Add extra cultures.
					foreach (var cultureName in cultureNames)
					{
						// Add engines.
						var c = new CultureInfo(cultureName);
						foreach (var engineName in voice.SupportedEngines)
						{
							var vx = new InstalledVoiceEx(voice);
							vx.SetCulture(c);
							vx.SourceRequestSpeed = elapsed;
							var keys = System.Web.HttpUtility.ParseQueryString("");
							keys.Add("source", vx.Source.ToString());
							keys.Add("region", r.SystemName);
							keys.Add("culture", cultureName);
							keys.Add("engine", engineName);
							vx.SourceKeys = keys.ToString();
							// Add voice.
							tempList.Add(vx);
							vex++;
							if (_CancelGetVoices)
								return null;
						}
					}
				}
				ControlsHelper.Invoke(() =>
				{
					StatusLabel.Text += string.Format(", VoicesEx={0}\r\n", vex);
				});
			}

			ControlsHelper.Invoke(() =>
			{
				StatusLabel.Text += "Done\r\n";
				//StatusPanel.Visible = true;
			});
			list = tempList;
			return list;
		}

		private void AmazonPolly_Exception(object sender, ClassLibrary.EventArgs<System.Exception> e)
		{
			throw new System.NotImplementedException();
		}

		/// <summary> 
		/// Clean up any resources being used.
		/// </summary>
		/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
		protected override void Dispose(bool disposing)
		{
			if (disposing)
			{
				_CancelGetVoices = true;
				if (components != null)
					components.Dispose();
			}
			base.Dispose(disposing);
		}
	}
}