import { Octokit } from "@octokit/rest";
import simpleGit from 'simple-git';
import fs from 'node:fs/promises';
import YAML from 'yaml';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
const docsPath = process.env.DOCS_PATH;
const numberOfDays = process.env.DAYS_TO_CHECK_FOR_DOCS_CHANGES || 7;

async function getPullRequestsForCommit(commitSha) {
  try {
    const { data: pulls } = await octokit.rest.repos.listPullRequestsAssociatedWithCommit({
      owner: 'Kong',
      repo: 'docs.konghq.com',
      commit_sha: commitSha,
    });

    return pulls;
  } catch (error) {
    console.error('Error fetching pull requests:', error);
    return [];
  }
}

async function getRecentCommits(repoPath, file) {
  const git = simpleGit(repoPath);
  const commits = [];

  try {
    const now = new Date();
    const since = new Date(now);
    since.setUTCDate(now.getUTCDate() - numberOfDays);
    since.setUTCHours(0, 0, 0, 0);
    const filePath = path.join(repoPath, file);

    try {
      await fs.access(filePath);
    } catch {
      console.log(`File ${file} does not exist in the repository.`);
      return [];
    }

    const log = await git.log({ file, '--since': `${since.toISOString()}` });

    if (log.total > 0) {
      for (const commit of log.all) {
        const prList = await getPullRequestsForCommit(commit.hash);
        commits.push({ commit, prList });
      }
    }
  } catch (error) {
    console.error('Error:', error);
  }

  return commits;
}

async function main() {
  try {
    console.log('Checking for changes...');
    const config = await fs.readFile(path.join(__dirname, './config/sources.yml'), { encoding: 'utf8' });
    if (config === '') {
      console.log('config/sources.yml is empty.')
      return;
    }
    const files = YAML.parse(config);
    const uniqueSources = new Set();
    let prsForSource = {};

    for (const sources of Object.values(files)) {
      sources.forEach(source => uniqueSources.add(source));
    }
    const sourcesArray = Array.from(uniqueSources);

    for (const source of sourcesArray) {
      const commits = await getRecentCommits(docsPath, source);
      const allPRs = commits.reduce((acc, { prList }) => {
        return acc.concat(prList);
      }, []);
      prsForSource[source] = [...new Map(allPRs.map(pr => [pr.number, pr])).values()];
    }

    for(const [file, sources] of Object.entries(files)) {
      console.log('----------------------------------------');
      console.log(`Dev Site file: ${file}`);
      console.log('Sources in docs.konghq.com:');
      for (const source of sources) {
        const prs = prsForSource[source];
        if (prs.length > 0) {
          console.log(` ${source}:`)
          console.log(prs.map(pr => `   #${pr.number} - ${pr.title} - ${pr.html_url}`).join('\n'));
        } else {
          console.log(` ${source}: No changes.`);
        }
      }
    }
    console.log('----------------------------------------');
    console.log('Done!');
  } catch (err) {
    console.error('Error reading or parsing YAML:', err);
  }
}

main();
