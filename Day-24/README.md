## Day 24: Advanced Git Integration Patterns
Welcome to the Day 24 module of the Production-Ready DevOps & SRE Journey, focusing on advanced branch integration, context switching, and selective commit extraction.
## 📁 Directory Structure

* 01-Day-24-Notes.md: Detailed concepts and technical Q&As.
* 02-Day-24-Cheat-Sheet.md: Compressed reference guide.

## 🗺️ Architectural Workflow

This interactive Mermaid diagram maps out the core integration pathways covered in this module, detailing when to deploy specific Git integration strategies based on development scenarios:


```mermaid
graph TD
    %% Base Styles
    classDef branch fill:#2b2b2b,stroke:#555,stroke-width:2px,color:#fff;
    classDef action fill:#1f4e79,stroke:#2e75b6,stroke-width:1px,color:#fff;
    classDef danger fill:#7030a0,stroke:#c00000,stroke-width:1px,color:#fff;
    classDef check fill:#228B22,stroke:#006400,stroke-width:1px,color:#fff;

    Start([Start Git Workflow]) --> Decision{What is your engineering intent?}
    
    %% Branch Integration Track
    Decision -->|Integrate Feature Branch| TargetCheck{Has the target branch changed?}
    TargetCheck -->|No new changes| FF[Fast-Forward Merge<br><code>git merge branch</code>]
    TargetCheck -->|Diverged target branch| MergeType{Preserve history or clean linear log?}
    
    MergeType -->|Preserve Complete History| ThreeWay[3-Way Merge Commit<br><code>git merge --no-ff branch</code>]
    MergeType -->|Flatten Intermediate History| Squash[Squash Merge<br><code>git merge --squash branch</code>]
    MergeType -->|Enforce Flat Timeline| Rebase[Rebase onto Target Branch<br><code>git rebase target</code>]

    %% Context Switching Track
    Decision -->|Handle Urgent Production Bug| StashCheck{Do you have raw workspace changes?}
    StashCheck -->|Yes, uncommitted| StashPush[Push to Stack<br><code>git stash push -m 'msg'</code>]
    StashPush --> SwitchHotfix[Checkout Hotfix Branch & Deploy Fix]
    SwitchHotfix --> ReturnBranch[Return to Original Branch]
    ReturnBranch --> StashPop[Restore Workspace Changes<br><code>git stash pop</code>]

    %% Cherry Pick Track
    Decision -->|Isolate One Bugfix| Cherry[Cherry-Pick Single Commit<br><code>git cherry-pick hash</code>]

    %% Rule Annotations
    Rebase --> RuleCheck{Is the branch pushed/shared?}
    RuleCheck -->|Yes| DangerZone[⚠️ STOP! Golden Rule Broken<br>Never Rebase Shared History]
    RuleCheck -->|No, local only| CleanTrack[Safe History Rewrite Completed]

    %% Apply Classes
    class FF,ThreeWay,Squash action;
    class Rebase,StashPush,StashPop,Cherry action;
    class DangerZone danger;
    class CleanTrack,CleanTrack check;
```

---


## 🚀 Key Topics Covered

   1. Git Merge Operations: Covers Fast-Forward, 3-Way, and Squash merges.
   2. Rebase & Timeline Linearization: History rewrite mechanics and the golden rule of rebasing shared branches.
   3. Context Switching: Shelving work via the stash stack (pop vs apply).
   4. Cherry-Picking: Pulling isolated commits into production tracks.
