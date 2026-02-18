import os
import subprocess
import shutil
import sys

def get_git_commit_hash():
    try:
        # Get short commit hash
        commit_hash = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD']).strip().decode('utf-8')
        return commit_hash
    except subprocess.CalledProcessError:
        print("Error: Could not get git commit hash. Is this a git repository?")
        return "unknown"
    except FileNotFoundError:
        print("Error: git command not found.")
        return "unknown"

def archive_report():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    report_source = os.path.join(project_root, 'report.md')
    reports_dir = os.path.join(project_root, 'reports')
    
    if not os.path.exists(report_source):
        print(f"Error: {report_source} not found.")
        return

    if not os.path.exists(reports_dir):
        os.makedirs(reports_dir)

    commit_hash = get_git_commit_hash()
    
    # Filename format: report_<commit_hash>.md
    destination_filename = f"report_{commit_hash}.md"
    destination_path = os.path.join(reports_dir, destination_filename)

    # Copy the file
    shutil.copy2(report_source, destination_path)

    # Append commit info to the file
    with open(destination_path, 'a', encoding='utf-8') as f:
        f.write(f"\n\n---\n**Report generated for commit:** `{commit_hash}`\n")
    
    print(f"Report archived successfully at: {destination_path}")

if __name__ == "__main__":
    archive_report()
